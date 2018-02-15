# Midburn Chatops

Serves the [Midburn Chatops Server](https://github.com/Midburn/midburn-chatops)


## Secrets

```
kubectl create secret generic chatops --from-literal=secret-slack-token=`read -p "Slack Bot Token: "; echo $REPLY`
```
