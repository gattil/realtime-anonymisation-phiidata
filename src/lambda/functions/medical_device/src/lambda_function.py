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
    patients = []

    with open('patients.csv', newline='') as csvfile:
        reader = csv.DictReader(csvfile)
        patients = list(reader)

    selected_patients = random.choices(range(len(patients)), k=int(enrolled_patients))

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

        # send record
        data = {
            "patient_uuid": row['Id'],
            'recording_time': dt_string,
            'location_lat': row['LAT'],
            'location_lon': row['LON'],
            "measurement_schema": "Glucose Profile",
            "measurement_insuline": str(random.randrange(10, 400)),
            "measurement_glucose": str(random.randrange(100, 250)),
            "measurement_temp": str(random.randrange(35, 40)),
        }

        outputs.append(firehose.put_record(
            DeliveryStreamName=delivery_stream,
            Record={
                'Data': json.dumps(data).encode('utf-8')
            }
        ))

    return {'records': outputs}
