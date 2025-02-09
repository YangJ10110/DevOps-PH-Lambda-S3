import json
import sqlite3
import boto3

# Fake Database Settings
db_name = ':memory:'  # In-memory SQLite DB

# Real S3 Settings
s3 = boto3.client('s3', region_name='us-east-1')

s3_bucket = os.environ['S3_BUCKET']


def setup_fake_db():
    """Creates a fake SQLite database and populates it with test data."""
    conn = sqlite3.connect(db_name)
    cursor = conn.cursor()
    cursor.execute("CREATE TABLE your_table (id INTEGER, name TEXT)")
    cursor.executemany("INSERT INTO your_table (id, name) VALUES (?, ?)", [(1, 'Alice'), (2, 'Bob')])
    conn.commit()
    return conn

def lambda_handler(event, context):
    """Lambda function that fetches data from SQLite (instead of MySQL) and uploads to real S3."""
    # Connect to fake DB
    connection = setup_fake_db()
    try:
        cursor = connection.cursor()
        cursor.execute("SELECT * FROM your_table")
        result = cursor.fetchall()
        
        # Convert query results to JSON
        json_data = json.dumps([{"id": row[0], "name": row[1]} for row in result])

        # get the number of objects in the S3 bucket
        response = s3.list_objects_v2(Bucket=s3_bucket)
        num_objects = response.get('KeyCount', 0)

        # Upload to Real S3

        s3_key = f'data_{num_objects + 1}.json'

        s3 = boto3.client('s3', region_name='us-east-1')
        s3.put_object(Bucket=s3_bucket, Key=s3_key, Body=json_data)
        
        return {'statusCode': 200, 'body': 'Data extracted and uploaded successfully'}

    except Exception as e:
        return {'statusCode': 500, 'body': f'Error: {str(e)}'}

    finally:
        connection.close()

# Run the test
# test 1
print(lambda_handler({}, {}))
