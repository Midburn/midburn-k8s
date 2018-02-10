# Dreams Helm sub-chart

Contains the Dreams web-app, DB and associated scripts

* Dreams Staging: https://dreams.staging.midbun.org/
* Dreams Production: **TODO**

## Secrets

```
  kubectl create secret generic dreams --from-literal=AWS_ACCESS_KEY_ID=*** \
                                       --from-literal=AWS_SECRET_ACCESS_KEY=*** \
                                       --from-literal=GOOGLE_APPS_SCRIPT=*** \
                                       '--from-literal=GOOGLE_APPS_SCRIPT_TOKEN=***' \
                                       '--from-literal=GOOGLE_CLIENT_SECRETS=***' \
                                       --from-literal=RAYGUN_APIKEY=*** \
                                       --from-literal=RECAPTCHA_SECRET_KEY=*** \
                                       --from-literal=RECAPTCHA_SITE_KEY=*** \
                                       --from-literal=S3_BUCKET_NAME=*** \
                                       --from-literal=SECRET_KEY_BASE=*** \
                                       --from-literal=SENDGRID_PASSWORD=*** \
                                       --from-literal=SENDGRID_USERNAME=***

  kubectl create secret generic dreams-otherdb --from-literal=HOST=*** \
                                               --from-literal=USER=*** \
                                               --from-literal=PASSWORD=*** \
                                               --from-literal=PORT=*** \
                                               --from-literal=DATABASE=***

kubectl create secret generic dreamsdb --from-literal=DATABASE_URL=postgres://***:***@***:5432/***
```
