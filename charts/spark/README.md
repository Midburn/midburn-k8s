# Spark Helm sub-chart

Contains the Spark web-app, DB and associated scripts

## DB configuration

The DB is available inside the cluster with the following credentials by default:

* host = `sparkdb`
* root password = `123456`
* spark user / password / database = `spark`

Adminer should be accessible at the main environment domain under `/adminer`

For a secure MySQL installation, set the following secrets, the sparkdb-root secret is accessible only to the mysql server pod

```
kubectl create secret generic sparkdb-root --from-literal=MYSQL_ROOT_PASSWORD=<ROOT_PASSWORD>
kubectl create secret generic sparkdb-app --from-literal=MYSQL_DATABASE=spark \
                                          --from-literal=MYSQL_USER=spark \
                                          --from-literal=MYSQL_PASSWORD=<SPARK_PASSWORD>
```

Set the values:

```
spark:
  rootSecretName: sparkdb-root
  appSecretName: sparkdb-app
```


## Mail configuration

[Sign up for mailjet google cloud promotion](https://www.mailjet.com/google/) to get 25,000 email per month for free

Get the username (api key) and password (secret key) and set in a secret:

```
kubectl create secret generic spark-mail --from-literal=SPARK_MAILSERVER_USER=<MAILSERVER_USER> \
                                         --from-literal=SPARK_MAILSERVER_PASSWORD=<MAILSERVER_PASSWORD>
```

Google cloud platform blocks standard email ports, luckily, Mailjet supports port 2525

```
spark:
  disableMailtrap: "true"
  secureMailserverSecretName: spark-mail
  mailserverFrom: <MAILSERVER_FROM_ADDRESS>
  mailserverHost: in-v3.mailjet.com
  mailserverPort: 2525
```


## Facebook Integration

```
kubectl create secret generic spark-facebook --from-literal=SPARK_FACEBOOK_SECRET=<FACEBOOK_SECRET_KEY>
```

```
spark:
  facebookSecretName: spark-facebook
```


## Recaptcha

```
kubectl create secret generic spark-recaptcha --from-literal=SPARK_RECAPTCHA_SITEKEY=<RECAPTCHA_SITEKEY> \
                                              --from-literal=SPARK_RECAPTCHA_SECRETKEY=<RECAPTCHA_SECRETKEY>
```

```
spark:
  recaptchaSecretName: spark-recaptcha
```


## Drupal

```
kubectl create secret generic spark-drupal --from-literal=DRUPAL_PROFILE_API_PASSWORD=<PASSWORD>
```

```
spark:
  drupalSecretName: spark-drupal
  drupalProfileApiURL: https://profile.midburn.org
  drupalProfileApiUser: <USER>
```


## Volunteers

```
spark:
  volunteersBaseUrl: http://volunteers.spark.midburn.org
```


## Restore from existing DB dump

Create the dump from the source DB and upload to Google Storage

```
mysqldump --host=<HOST> --port=3306 --protocol=tcp --user=<ROOT_USER> --password=<ROOT_PASSWORD> \
          --all-databases > "sparkdb-dump-`date +%Y-%m-%d-%H-%M`.sql"
gsutil mb gs://midburn-db-dumps/
gsutil cp "sparkdb-dump-`date +%Y-%m-%d-%H-%M`.sql" gs://midburn-db-dumps/
```

Set the values

```
spark:
  dbImportOpsImage: orihoch/midburn-k8s@sha256:d646e3ea874043dc37ea22ab8b59ffde2f6ffc69e6543801b64122c963e5c5b9
  dbImportJobSuffix: "2017-12-16-08-10"
  dbImportUrl: "gs://midburn-db-dumps/spark-staging-db-dump-2017-12-16-08-10.sql"
```

Deploy - `./helm_upgrade.sh`

Wait for import job to complete - `kubectl describe job sparkdb-import-2017-12-16-08-10`

Get the job logs (the pod id appears at the bottom of the job describe output) - `kubectl logs <JOB_POD_ID>`
