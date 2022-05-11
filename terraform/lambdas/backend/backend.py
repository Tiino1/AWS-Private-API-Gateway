from datetime import datetime

def handler(event, context):
    print(event)
    print("My first backend")
    return {
        "statusCode": 200,
        "body": "Damnnnnnnnn ! " + str(datetime.now())
    }
