Add following lines to .env

```
SEE_THROUGH_GH_CLIENT_ID
SEE_THROUGH_GH_CLIENT_SECRET
SEE_THROUGH_HOME_PATH
SEE_THROUGH_TOKEN
SEE_THROUGH_SLACK_TOKEN
SEE_THROUGH_EMAIL
SEE_THROUGH_EMAIL_PASS
DEBUG_EMAIL

```
## How to register github application

You have to register github OAuth application in order to gain CLIENT_ID and CLIENT_SECRET keys
- Go to https://github.com/settings/applications
- Set:
```
application name = SeeThrough
homepage URL = http://localhost:4567/
and authorization callback URL = http://localhost:4567/callback
```