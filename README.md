# notifications-email-provider-stub

During load testing, instead of sending requests to AWS SES to send emails we want to stub them out so that we don't incur unnecessary costs.

When the API tries to send an email, instead of using Boto and talking to AWS SES, you can use the `AwsSesStubClient` to send an HTTP POST request to this stub app to mimic the behaviour of SES.

When this stub app receives a POST request from the API to send an email, it will:

- put a task on the ses-callback queue with a fake SES callback
- respond with a fake `messageID` to be used as the reference from SES

## To run the application

```
make bootstrap

source .envrc  # not needed if you have direnv installed

NOTIFICATION_QUEUE_PREFIX=<your-queue-prefix> make run
```
Then visit http://localhost:6301/ to see it running

### How to make the API use this email provider stub

You will need to set the environment variable `SES_STUB_URL` for API apps in your chosen environment, for example:

```
SES_STUB_URL=http://notify-email-provider-stub-staging.apps.internal:8080/ses
```
