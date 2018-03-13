# Spark Helm chart

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

Daily dumps are uploaded to google storage

Import from a dump using `charts-external/spark/recreate_db.sh`


## Starting a testing environment

Copy all the files from `charts-external/spark/testing-environment-template` directory to midburn-k8s repository

It should be under `environments/ENVIRONMENT_NAME` - replace ENVIRONMENT_NAME with the name of the new environment.

Edit the files and modify all occurences of ENVIRONMENT_NAME

Replace the DB import job url - to get a newer DB dump / from a different environment

Replace the Spark docker image

Switch to the new environment and deploy the spark chart

```
source switch_environment.sh ENVIRONMENT_NAME;
./helm_upgrade_external_chart.sh spark --dry-run --install && ./helm_upgrade_external_chart.sh spark --install
```

Use port forwarding to test the spark pod directly

```
kubectl port-forward "`kubectl get pods -o json -l app=spark | jq -r '.items[0].metadata.name'`" 3000
```

Spark should be available at http://localhost:3000

You can access the DB from the staging adminer at https://staging.midburn.org/adminer

System: MySQL, Server: sparkdb.ENVIRONMENT_NAME, Username: root, Password: 123456, Database: spark

You can also configure the staging load balancer to expose the environment under a domain

Create a DNS A Record (In Midburn's AWS Route 53 service), e.g. from spark.ENVIRONMENT_NAME.midburn.org to staging.midburn.org IP address

Edit `environments/staging/values.yaml` - add the domain to the traefik acmeDomains setting and the customFrontends and customBackends traefik configuration

See [this commit](https://github.com/Midburn/midburn-k8s/commit/4ca4f894151a494b41d2a1b2f36f6f0235424994) for an example of the required changes

After root chart deployment to staging, you should be able to access the testing spark at spark.ENVIRONMENT_NAME.midburn.org

When you are done with the testing environment, delete it:

```
source switch_environment.sh ENVIRONMENT_NAME; ./helm_remove_all.sh && rm -rf environments/ENVIRONMENT_NAME
```
