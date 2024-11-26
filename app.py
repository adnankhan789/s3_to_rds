import boto3
import pymysql
import os
import csv

# Fetch environment variables
S3_BUCKET = os.getenv("S3_BUCKET")
S3_KEY = os.getenv("S3_KEY")
RDS_HOST = os.getenv("RDS_HOST")
RDS_USER = os.getenv("RDS_USER")
RDS_PASSWORD = os.getenv("RDS_PASSWORD")
RDS_DB = os.getenv("RDS_DB")

# Function to read data from S3
def read_from_s3():
    s3 = boto3.client('s3')
    response = s3.get_object(Bucket=S3_BUCKET, Key=S3_KEY)
    csv_data = response['Body'].read().decode('utf-8').splitlines()
    data = list(csv.DictReader(csv_data))
    return data

# Function to insert data into RDS
def write_to_rds(records):
    connection = pymysql.connect(
        host=RDS_HOST,
        user=RDS_USER,
        password=RDS_PASSWORD,
        db=RDS_DB
    )
    cursor = connection.cursor()
    for record in records:
        cursor.execute("""
            INSERT INTO people (name, age, gender, profession)
            VALUES (%s, %s, %s, %s)
        """, (record['name'], record['age'], record['gender'], record['profession']))
    connection.commit()
    cursor.close()
    connection.close()

# Lambda handler
def handler(event, context):
    try:
        data = read_from_s3()
        write_to_rds(data)
        return {"status": "success", "message": f"{len(data)} records inserted"}
    except Exception as e:
        return {"status": "error", "message": str(e)}
