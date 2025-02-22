import json
import sqlite3
import boto3
import os

# Fake Database Settings (Store in /tmp/ for reuse)
db_path = "/tmp/fake_db.sqlite"

s3_bucket = os.environ.get('S3_BUCKET')

def setup_fake_db():
    """Creates a fake SQLite database if it does not exist."""
    if not os.path.exists(db_path):
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        cursor.execute("CREATE TABLE your_table (id INTEGER, name TEXT)")
        cursor.executemany("INSERT INTO your_table (id, name) VALUES (?, ?)", [(1, 'Alice'), (2, 'Bob')])
        conn.commit()
        conn.close()

def lambda_handler(event, context):
    """Fetches data from SQLite and uploads to real S3."""
    setup_fake_db()  # Ensure DB is set up
    
    # Connect to DB
    connection = sqlite3.connect(db_path)
    try:
        cursor = connection.cursor()
        cursor.execute("SELECT * FROM your_table")
        result = cursor.fetchall()
        
        # Convert query results to JSON
        json_data = json.dumps([{"id": row[0], "name": row[1]} for row in result])

        # Upload to Real S3
        s3 = boto3.client('s3', region_name='us-east-1')
        
        # Get number of objects in the bucket
        s3_objects = s3.list_objects_v2(Bucket=s3_bucket)
        num_objects = s3_objects.get('KeyCount', 0)  # FIXED ERROR

        s3_key = f'output_{num_objects + 1}.json'

        s3.put_object(Bucket=s3_bucket, Key=s3_key, Body=json_data)
        
        return {'statusCode': 200, 'body': 'Data extracted and uploaded successfully'}

    except Exception as e:
        return {'statusCode': 500, 'body': f'Error: {str(e)}'}

    finally:
        connection.close()

# Test Lambda function
# test 1
print(lambda_handler({}, {}))
