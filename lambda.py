import json
import boto3
import pymysql

# Database settings
db_host = 'your_db_host'
db_user = 'your_db_user'
db_password = 'your_db_password'
db_name = 'your_db_name'

# S3 settings
s3_bucket = 'your_s3_bucket'
s3_key = 'your_s3_key.json'

def lambda_handler(event, context):
    # Connect to the database
    connection = pymysql.connect(host=db_host,
                                 user=db_user,
                                 password=db_password,
                                 database=db_name)
    
    try:
        with connection.cursor() as cursor:
            # Execute SQL query
            sql = "SELECT * FROM your_table"
            cursor.execute(sql)
            result = cursor.fetchall()
        
        # Convert the result to JSON
        json_data = json.dumps(result, default=str)
        
        # Upload JSON to S3
        s3 = boto3.client('s3')
        s3.put_object(Bucket=s3_bucket, Key=s3_key, Body=json_data)
        
        return {
            'statusCode': 200,
            'body': json.dumps('Data successfully extracted and uploaded to S3')
        }
    
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error: {str(e)}')
        }
    
    finally:
        connection.close()