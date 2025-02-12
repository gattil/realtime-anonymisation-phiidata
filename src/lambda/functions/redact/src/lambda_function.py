import json
import boto3
import os
import base64
import sys
from logger import logger
# Creates Comprehend client
comprehend_client = boto3.client('comprehendmedical')

# Gathers keys from enviroment variables and makes a list of desired keys to check for PII
redact_keys = os.environ['redact_keys'].split(",")
pii_keys = os.environ['pii_evalutation'].split(",")


def lambda_handler(event, context):
    output = []
    logger.debug("Event", extra=dict(data=event))
    for record in event['records']:
        # decode base64
        # Kinesis data is base64 encoded so decode here
        payloadraw = base64.b64decode(record["data"]).decode('utf-8').replace('\n', '').replace('\r', '')
        # Loads decoded payload into json
        payloadjsonraw = json.loads(payloadraw)
        logger.debug("Payload", extra=dict(data=payloadjsonraw))
        # This codes handles the logic to check for keys, identify if PII exists, and redact PII if available.
        logger.debug("payload", extra=dict(data=payloadjsonraw))
        for i in payloadjsonraw:
            # Redact keys
            if i in redact_keys:
                payloadjsonraw[i] = len(payloadjsonraw[i]) * "*"

            elif i in pii_keys:
                # checks if the key found in the message matches a redact
                logger.debug("Redact key found, checking for PII")
                payload = str(payloadjsonraw[i])
                # check if payload size is less than 100KB
                if sys.getsizeof(payload) < 99999:
                    logger.debug('Size is less than 100KB checking if value contains PII')
                    # Runs Comprehend ContainsPiiEntities API call to see if key value contains PII
                    #pii_identified = comprehend_client.contains_pii_entities(Text=payload, LanguageCode='en')
                    pii_identified = comprehend_client.detect_entities_v2(Text=payload)

                    if pii_identified:
                        # if PII is found, run through redaction logic
                        logger.debug('PII found redacting')
                        # Runs Comprehend DetectPiiEntities call to find exact location of PII
                        response = comprehend_client.detect_entities_v2(Text=payload)
                        entities = response['Entities']
                        logger.debug("Entities", extra=dict(data=entities))
                        # creates redacted_payload which will be redacted
                        redacted_payload = payload
                        # runs through a loop that gathers necessary values from Comprehend API response and redacts values
                        for entity in entities:
                            if entity['Category'] == "PROTECTED_HEALTH_INFORMATION":
                                char_offset_begin = entity['BeginOffset']
                                char_offset_end = entity['EndOffset']
                                redacted_payload = redacted_payload[:char_offset_begin] + '*' * (
                                        char_offset_end - char_offset_begin) + redacted_payload[char_offset_end:]
                        # replaces original value with redacted value
                        payloadjsonraw[i] = redacted_payload

                    else:
                        # If PII is not found, skip over key
                        logger.debug('No PII found')
                    logger.info(str(payloadjsonraw[i]))
                else:
                    logger.debug('Size is more than 100KB, skipping inspection')
            else:
                logger.debug("Key value not found in redaction list")

        redacteddata = json.dumps(payloadjsonraw)

        # adds inspected record to record
        output_record = {
            'recordId': record['recordId'],
            'result': 'Ok',
            'data': base64.b64encode(redacteddata.encode('utf-8'))
        }
        output.append(output_record)
        logger.debug(output_record)

    logger.debug('Successfully processed {} records.'.format(len(event['records'])))

    return {'records': output}
