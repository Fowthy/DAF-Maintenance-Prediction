from datetime import datetime
import influxdb_client, os, time
from influxdb_client import InfluxDBClient, Point, WritePrecision
from influxdb_client.client.write_api import SYNCHRONOUS
import csv

token = "yffucGPRYgFfDlC0ZQUeSh8am4sZ-9B8LcG8o4fwXe9QOfzxrvsBYKq4Aar6R8o8iJOGwBls7MnFvUcSGznG5A=="
org = "Bulgarski Software 1"
url = "https://eu-central-1-1.aws.cloud2.influxdata.com"
bucket = "daff"

client = InfluxDBClient(url=url, token=token)
write_api = client.write_api(write_options=SYNCHRONOUS)

# Open the CSV file
with open('C:\Semester 6\daf2.csv', 'r') as file:
    reader = csv.reader(file)
    header = next(reader)

    # Iterate over each row in the CSV
    for row in reader:
        # Create a new Point
        point = Point("BFC_SOURCE_ID")  # Replace "measurement_name" with your actual measurement name

        # Convert the timestamp to Unix timestamp format
        timestamp_str = row[header.index('BFC_TIMESTAMP')].strip('"')
        dt = datetime.strptime(timestamp_str, "%Y-%m-%d %H:%M:%S.%f")
        timestamp_ns = int(dt.timestamp() * 1e9)

        # Set the timestamp
        point.time(timestamp_ns, WritePrecision.NS)

        # Set the rest of the fields
        for i, item in enumerate(row):
            if i != header.index('BFC_TIMESTAMP'):
                # Check if the item is 'NULL'
                if item == 'NULL':
                    point.field(header[i], None)
                else:
                    point.field(header[i], float(item))

        # Write the point to InfluxDB
        write_api.write(bucket, org, point)