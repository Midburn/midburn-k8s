# Volunteers Helm sub-chart

Contains the Volunteers web-app, DB and associated scripts


## JWT secret

```
kubectl create secret generic volunteers-jwt --from-literal=SECRET=`date +%s | sha256sum | base64 | head -c 32 ; echo`
```

```
volunteers:
  jwtSecretName: volunteers-jwt
```


## Exporting mongo from old servers

Get the dump from an old server and upload to google storage

```
ssh old-server
rm -rf mongodump mongodump.tar.gz
mongodump -omongodump -dvolunteers
tar -czvf mongodump.tar.gz mongodump
exit
rm mongodump.tar.gz
scp old-server:mongodump.tar.gz ./
gsutil mb gs://midburn-db-dumps/
gsutil cp mongodump.tar.gz gs://midburn-db-dumps/volunteersdb-mongodump-`date +%Y-%m-%d-%H-%M`.tar.gz
rm mongodump.tar.gz
echo "gs://midburn-db-dumps/volunteersdb-mongodump-`date +%Y-%m-%d-%H-%M`.tar.gz"
```

