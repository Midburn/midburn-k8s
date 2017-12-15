# Spark Helm sub-chart

MySQL (MariaDB) database used for Spark

Available internally:

* host = `sparkdb`
* root password = `123456`
* spark user / password / database = `spark`

## sparkdb secret

```
kubectl create secret generic sparkdb --from-literal=MYSQL_ROOT_PASSWORD=<ROOT_PASSWORD> \
                                      --from-literal=MYSQL_DATABASE=spark \
                                      --from-literal=MYSQL_USER=spark \
                                      --from-literal=MYSQL_PASSWORD=<SPARK_PASSWORD>
```

Set the secret name in values to enable:

```
global:
  sparkdbSecretName: sparkdb
```
