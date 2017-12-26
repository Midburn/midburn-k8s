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
