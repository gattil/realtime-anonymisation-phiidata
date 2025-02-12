import json
import boto3
import os
import base64
import sys
from logger import logger
from datetime import datetime
import csv
import random

# Creates Comprehend client
firehose = boto3.client('firehose')
delivery_stream = os.getenv('delivery_stream', '')


def lambda_handler(event, context):
    logger.debug("Event", extra=dict(data=event))
    outputs = []
    enrolled_patients = event['enrolled_patients']
    physician_notes = []
    patients = []

    with open('notes.csv', mode='r', newline='') as file:
        physician_notes = [line.rstrip() for line in file]

    with open('patients.csv', newline='', mode='r') as csvfile:
        reader = csv.DictReader(csvfile)
        patients = list(reader)

    selected_patients = random.choices(range(len(patients)), k=int(enrolled_patients))
    selected_notes = random.choices(range(len(physician_notes)), k=int(enrolled_patients))

    for i in range(int(enrolled_patients)):
        row = patients[selected_patients[i]]

        now = datetime.now()
        dt_string = now.strftime("%d/%m/%Y %H:%M:%S")

        # Schema
        # device_uui string,
        # name string,
        # birthdate string,
        # ssn string,
        # address string,
        # gender string,
        # location_lat string,
        # location_lon string,
        # recording_time string,
        # measurement_schema string,
        # measurement_insuline string,
        # measurement_glucose string,
        # measurement_temp string

        patient_name = ''.join(filter(lambda x: not x.isdigit(), row['FIRST'])) + " " + ''.join(
            filter(lambda x: not x.isdigit(), row['LAST']))
        # send record
        data = {
            "patient_uuid": row['Id'],
            'recording_time': dt_string,
            'name': patient_name,
            'birthdate': row['BIRTHDATE'],
            'ssn': row['SSN'],
            'address': row['ADDRESS'] + ", " + row['CITY'],
            'gender': row['GENDER'],
            "physician_annotation": physician_notes[selected_notes[i]].format(patient_name)
        }

        outputs.append(firehose.put_record(
            DeliveryStreamName=delivery_stream,
            Record={
                'Data': json.dumps(data).encode('utf-8')
            }
        ))

    return {'records': outputs}
