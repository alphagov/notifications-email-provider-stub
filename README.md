# notifications-email-provider-stub

## What this does
During load testing, instead of sending requests to AWS SES to send emails we want to stub them out so that we don't incur unnecessary costs.

When the API tries to send an email, instead of using Boto and talking to AWS SES, you can use the `AwsSesStubClient` to send an HTTP POST request to this stub app to mimic the behaviour of SES. 

When this stub app receives a POST request from the API to send an email, it will
- put a task on the ses-callback queue with a fake SES callback 
- respond with a fake `messageID` to be used as the reference from SES

## To run the application

```
make bootstrap

NOTIFICATION_QUEUE_PREFIX=<your-queue-prefix> make run
```
Then visit http://localhost:6301/ to see it running

## To deploy the application

To deploy:

```
make bootstrap
make preview cf-deploy
```

### How to make the API use this email provider stub

You will need to set the environment variable `SES_STUB_URL` for API apps in your chosen environment, for example:

```
cf set-env APP-NAME SES_STUB_URL https://notify-email-provider-stub-staging.cloudapps.digital/ses
cf restage APP-NAME
```

It is suggested to turn it on for minimum the `notify-api`, `notify-delivery-worker-sender` and `notify-delivery-worker-retry-tasks`. By not turning it on for `notify-delivery-worker-internal`, which is responsible for delivering MFA codes, it will mean you can still log into the environment.

### Scaling

You may need to scale up the number of instances to handle the load you point at this stub. Initial testing using Vegeta shows that to handle 400 requests per second with a 50th percentile response time under 100ms you need about 10-20 instances.

```
cf scale notify-email-provider-stub -i 10
```
