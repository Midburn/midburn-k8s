# Loomio Helm sub-chart

## secrets

```
SECRET_COOKIE_TOKEN=`openssl rand -base64 48`
DEVISE_SECRET=`openssl rand -base64 48`
 PGPASS=
 DATABASE_URL=postgresql://postgres:$PGPASS@loomio-db/loomio_production
 SMTP_PASSWORD=
 SMTP_USERNAME=

kubectl create secret generic loomio-db --from-literal=POSTGRES_PASSWORD=$PGPASS
kubectl create secret generic loomio \
    --from-literal=DATABASE_URL=$DATABASE_URL \
    --from-literal=SECRET_COOKIE_TOKEN=$SECRET_COOKIE_TOKEN \
    --from-literal=DEVISE_SECRET=$DEVISE_SECRET \
    --from-literal=SMTP_USERNAME=$SMTP_USERNAME \
    --from-literal=SMTP_PASSWORD=$SMTP_PASSWORD
```
