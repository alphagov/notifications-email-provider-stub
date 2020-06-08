import datetime
import json
import logging
import os
import uuid

from celery import Celery
from flask import Flask, jsonify

QUEUE_NAME = os.environ['NOTIFICATION_QUEUE_PREFIX'] + "ses-callbacks"


CONFIG = {
    'BROKER_URL': 'sqs://',
    'BROKER_TRANSPORT_OPTIONS': {
        'region': 'eu-west-1',
        'visibility_timeout': 310,
    },
    'CELERY_TASK_SERIALIZER': 'json'
}

app = Flask(__name__)

logging.debug('invisible magic')  # this activates level setting. Without it logger does not log info level logs:
#  https://stackoverflow.com/questions/43109355/logging-setlevel-is-being-ignored

logger = logging.getLogger()
logger.setLevel("INFO")

celery = Celery()
celery.config_from_object(CONFIG)


@app.route('/')
def index():
    return "Healthy"


@app.route('/ses', methods=['GET', 'POST'])
def ses():
    message_id = str(uuid.uuid4())
    response_dict = {"MessageId": message_id}
    celery_data = {
        "Message": json.dumps({
            "mail": {
                "messageId": message_id,
                "timestamp": datetime.datetime.utcnow().isoformat()
            },
            "notificationType": "Delivery"
        })
    }
    logger.info(f"Sending email callback for message id {message_id}")
    try:
        celery.send_task(name='process-ses-result', args=(celery_data,), queue=QUEUE_NAME, countdown=2)
    except Exception as e:
        logger.error(e)
        raise e

    return jsonify(response_dict)


if __name__ == '__main__':
    app.run(debug=True,host='0.0.0.0')
