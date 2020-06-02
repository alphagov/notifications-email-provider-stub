# notifications-email-provider-stub

## What this does
During load testing, instead of sending requests to AWS SES to send emails we want to stub them out so that we don't incur unnecessary costs.

When the API tries to send an email, instead of using Boto and talking to AWS SES, you can use the `AwsSesStubClient` to send an HTTP POST request to this stub app to mimic the behaviour of SES. 

When this stub app receives a POST request from the API to send an email, it will
- put a task on the ses-callback queue with a fake SES callback 
- respond with a fake `messageID` to be used as the reference from SES


## Set up

To run locally

```
pip install -r requirements.txt
make run
```
Then visit http://localhost:6301/ to see it running

## Deploy

Should only be deployed to preview and staging environments. It will not work on a local development environment because we do not support SES callbacks on local environments (there is no Lambda function or SQS queue to process them).

To deploy:

`make preview cf-push`

So this app can put tasks on our SQS queues, you will need to give it appropriate AWS environment variables.

```
cf set-env notify-email-provider-stub AWS_ACCESS_KEY_ID <access_key_id>
cf set-env notify-email-provider-stub AWS_SECRET_ACCESS_KEY <secret_access_key>
cf restage notify-email-provider-stub
```

## How to make the API use this email provider stub

You will need to set the environment variable `SES_STUB_URL` on the API in your chosen environment, for example:

```
cf set-env notify-api SES_STUB_URL https://notify-email-provider-stub-preview.cloudapps.digital/ses
cf restage notify-api
```

This will mean that the API will use the `AwsSesStubClient` automatically.
