# The Midburn Kubernetes Environment

## Why can't it just work all the time?

[![it can - with Kubernetes!](it-can-with-kubernetes.png)](https://cloud.google.com/kubernetes-engine/kubernetes-comic/)

https://cloud.google.com/kubernetes-engine/kubernetes-comic/


## Interacting with the environment

You can interact with the Kubernetes environment in the following ways - 

* GitHub - commits to master branch are continuously deployed to the relevant environment. See .travis.yaml for the continuous deployment configuration and deployed environments.
* [Google Cloud Shell](https://cloud.google.com/shell/docs/quickstart) - The recommended and easiest way for running management commands. Just setup a Google Cloud account and enable billing (you get 300$ free, you can setup billing alerts to avoid paying by mistake). You can use the cloud shell file editor to edit files, just be sure to configure it to indentation of 2 spaces (not tabs - because they interfere with the yaml files).
* Any modern PC / OS should also work, you will just need to install some basic dependencies like Docker and Google Cloud SDK (possibly more). The main problem with working from local PC is the network connection, if you have a stable, fast connection and know how to install the dependencies, you might be better of running from your own PC.
* Docker + Google Cloud service account - for automation / CI / CD. See the Docker Ops section below for more details.


## Initial installation and setup

Ensure you have permissions on the relevant Google Project. Permissions are personal, so once you authenticate with your google account, you will have all permissions granted for you by the different Google Cloud projects.

To interact with the environment locally, install [Google Cloud SDK](https://cloud.google.com/sdk/) and run `gcloud auth login` to authenticate.

On Google Cloud Shell you are already authenticated and all dependencies are installed.

Clone the repo

```
git clone https://github.com/Midburn/midburn-k8s.git
```

All following commands should run from the midburn-k8s directory

```
cd midburn-k8s
```


## Connect to an existing environment

The main environments should be committed to this repo under `environments` directory

Each directory under `environments` corresponds to an environment name which you can connect to:

```
source switch_environment.sh ENVIRONMENT_NAME
```

Make sure you are connected to the correct environment before running any of the following commands.


## Releases and deployments

[Helm](https://github.com/kubernetes/helm) manages everything for us.

Notes regarding deployment to the main, shared environments (`staging` / `production`):
  * The preferred way to deploy is by opening and merging a pull request - this prevents infrastructure deployment risks and is generally more secure.
  * If you intend to do some infrastructure development, consider creating your own personal environment and testing on that.
  * If you want to update an attribute of a specific deployment, see the section below - Patching configuration values without Helm

If you still want to deploy directly, just make sure you are the only one working on the environment and/or update with the master branch to prevent infrastructure conflicts.

Make sure you have the latest helm installed on both client and server: 

```
kubectl create -f rbac-config.yaml
helm init --service-account tiller
```

Deploy:

```
./helm_upgrade.sh
```

When helm upgrade command completes successfully it doesn't necesarily mean deployment is complete (although it often does) - it only updates the desired state.

Kubernetes / Helm have a desired state of the infrastructure and they will do their best to move to that state.

You can add arguments to `./helm_upgrade.sh` which are forwarded to the underlying `helm upgrade` command.

Check [the Helm documentation](https://docs.helm.sh/) for more details.

Some useful arguments:

* For initial installation you should add `--install`
* Depending on the changes you might need to add `--recreate-pods` or `--force`
* For debugging you can also use `--debug` and `--dry-run`

Additionally, you can to use `force_update.sh` to force an update on a specific deployment.


## Helm configuration values

The default values are at `values.yaml` - these are used in the chart template files (under `templates` and `charts` directories)

Each environment can override these values using `environments/ENVIRONMENT_NAME/values.yaml`

Finally, automation scripts write values to `environments/ENVIRONMENT_NAME/values.auto-updated.yaml` using the `update_yaml.py` script


## Secrets

Secrets are stored and managed directly in kubernetes and are not managed via Helm.

To update an existing secret, delete it first `kubectl delete secret SECRET_NAME`

After updating a secret you should update the affected deployments, you can use `./force_update.sh` to do that

All secrets are optional so you can run the environment without any secretes and will use default values similar to dev environments.

Each environment may include a script to create the environment secrets under `environments/ENVIRONMENT_NAME/secrets.sh` - this file is not committed to Git.

You can use the following snippet in the secrets.sh script to check if secret exists before creating it:

```
! kubectl describe secret <SECRET_NAME> &&\
  kubectl create secret generic <SECRET_NAME> <CREATE_SECRET_PARAMS>
```


## Subcharts

Some components are defined in Helm sub charts under `charts` directory.

Each sub-chart has a README.md with details about setting up and using that chart.


## Create a new environment

Each environment should have the following files:

- `environments/ENVIRONMENT_NAME/.env` *(required)*: the basic environment connection details
- `environments/ENVIRONMENT_NAME/values.yaml` *(optional)*: override default helm chart values for this environment
- `environments/ENVIRONMENT_NAME/values.auto-updated.yaml` *(optional)*: override environment values from automatically updated actions (e.g. continuous deployment)
- `environments/ENVIRONMENT_NAME/secrets.sh` *(optional)* create the secrets for this environment, shouldn't be committed to Git.

You don't have to create a new cluster for each environment, you can use namespaces to differentiate between environments and keep everything on a single cluster.

If you are using an existing cluster, skip to "once the cluster is running" below

Get the available Kubernetes versions:

```
gcloud --project=<GOOGLE_PROJECT_ID> container get-server-config --zone=us-central1-a
```

Create a cluster (modify version to latest from previous command):

```
gcloud --project=<GOOGLE_PROJECT_ID> container clusters create --zone=us-central1-a <CLUSTER_NAME> \
                                                               --cluster-version=1.8.4-gke.0 \
                                                               --num-nodes=1
```

Once the cluster is running, connect to the environment:

```
source switch_environment.sh ENVIRONMENT_NAME
```

If it's a new cluster - install the Helm server-side component

```
helm init
```


## Docker OPS

To faciliate CI/CD and other automated flows you can use the provided ops Dockerfile.

You should get the `secret-midburn-k8s-ops.json` file from a team member (see below for how to create it)

Once you have this file in the current directory you can run the following to start a bash session in staging environment:

Assuming you have the service account secret available at `secret-midburn-k8s-ops.json` you can run the following to start an interactive bash session:

```
./run_docker_ops.sh staging
```

Inside the environment you can run all ops scripts and kubectl commands

For security, the docker ops by default downloads a fresh copy of midburn-k8s repo and docker image, to use the local directory (assuming you are inside the midburn-k8s directory):

```
./run_docker_ops.sh staging "" "." "."
```


## Building and publishing the OPS image

The OPS docker image should be publically available on docker hub

Pull the docker image which is built by the continuous deployment

```
gcloud docker -- pull gcr.io/uumpa123/midburn-k8s
```

Tag and push to docker hub

```
docker tag gcr.io/uumpa123/midburn-k8s orihoch/midburn-k8s
```

Update the image in the run_docker_ops.sh script using the sha256: id to refer to the image:

```
orihoch/midburn-k8s@sha256:95f0cb600504dd891aa8a4dba25aef63091984da27d0c3072085673665fb4cd6
```


## Enable the ops management pos

Create the ops secret to allow using the ops deployment to run management tasks from inside the cluster:

```
kubectl create secret generic midburn-k8s-ops "--from-file=secret.json=environments/${K8S_ENVIRONMENT_NAME}/secret-midburn-k8s-ops.json"
```

Set in values

```
global:
  k8sOpsSecretName: midburn-k8s-ops
  k8sOpsImage: orihoch/midburn-k8s@sha256:dc3531820588d0b217a2e4af0432e492900cc78efd078a9a555889f80f015222
```

You can now `kubectl exec -it` to this pod to run management commands inside the cluster


## Creating a new service account and secret-midburn-k8s-ops.json file

```
export SERVICE_ACCOUNT_NAME="midburn-k8s-ops"
export SERVICE_ACCOUNT_ID="${SERVICE_ACCOUNT_NAME}@${CLOUDSDK_CORE_PROJECT}.iam.gserviceaccount.com"
gcloud iam service-accounts create "${SERVICE_ACCOUNT_NAME}"
gcloud iam service-accounts keys create "--iam-account=${SERVICE_ACCOUNT_ID}" "secret-midburn-k8s-ops.json"
```

Add admin roles for common services:

```
gcloud projects add-iam-policy-binding --role "roles/storage.admin" "${CLOUDSDK_CORE_PROJECT}" \
                                       --member "serviceAccount:${SERVICE_ACCOUNT_ID}"
gcloud projects add-iam-policy-binding --role "roles/cloudbuild.builds.editor" "${CLOUDSDK_CORE_PROJECT}" \
                                       --member "serviceAccount:${SERVICE_ACCOUNT_ID}"
gcloud projects add-iam-policy-binding --role "roles/container.admin" "${CLOUDSDK_CORE_PROJECT}" \
                                       --member "serviceAccount:${SERVICE_ACCOUNT_ID}"
gcloud projects add-iam-policy-binding --role "roles/viewer" "${CLOUDSDK_CORE_PROJECT}" \
                                       --member "serviceAccount:${SERVICE_ACCOUNT_ID}"
```


## Patching configuration values without Helm

This method works in the following conditions:

* You want to make changes to a main / shared environment (`production` / `staging`) - otherwise, just do a helm upgrade.
* You want to modify a specific value in a specific resource (usually a deployment)
* This value is represented in the Helm configuration values

Update the auto-updated yaml value/s

```
./helm_update_values.sh '{"spark":{"image":"orihoch/spark:testing123"}}'
```

Commit and push to GitHub master branch. It's important to commit the changes to Git **first** and only then patch the deployment - this prevents infrastrcuture conflicts.

Patch the deployment and wait for successful rollout

```
kubectl set image deployment/spark spark=orihoch/spark:testing123
kubectl rollout status deployment spark
```


## Patching configuration values from CI / automation scripts

Create a [GitHub machine user](https://developer.github.com/v3/guides/managing-deploy-keys/#machine-users).

Give this user write permissions to the k8s repo.

Set the following environment variables in the CI environment:

* `K8S_OPS_GITHUB_REPO_TOKEN` - the machine user's token
* `DEPLOYMENT_BOT_EMAIL` - you can make up any email, it will show up in the commit
* `DEPLOYMENT_BOT_NAME` - same as the email, can be any name

Run the `helm_update_values.sh` script from an authenticated OPS container connected to the relevant environment

```
./helm_update_values.sh '{"spark":{"image":"orihoch/spark:testing123"}}' "${K8S_ENVIRONMANE_NAME} environment - spark image update --no-deploy"
```

Add the `--no-deploy` argument to the commit message to prevent automatic deployment if you want to deploy manually

To patch the resource manually, you could run something like this afterwards:

```
kubectl set image deployment/spark spark=orihoch/spark:testing123
kubectl rollout status deployment spark
```


## Continuous Deployment

Each app / module is self-deploying using the above method for patching configurations

The continuous deployment flow is based on:

* Travis - runs the deployment script on each app's repo on commit to master branch (AKA merge of PR).
* Ops Docker (see above) - provides a consistent deployment environment and to securely authenticate with the service account secret.
* GitHub - for persistency of deployment environment values - GitHub maintains the state of the environment. Each app commits deployment updates to the k8s repo.

We use [Travis CLI](https://github.com/travis-ci/travis.rb#installation) below but you can also do the setup from the UI.

Enable Travis for the repo (run `travis enable` from the repo directory)

Copy `.travis.yml` from this repo to the app repo and modify the values / script according to your app requirements

Set the k8s ops service account secret on the app's travis

This command should run from the root of the external app, assuming the midburn-k8s repo is a sibling directory:

```
travis encrypt-file ../midburn-k8s/secret-midburn-k8s-ops.json secret-midburn-k8s-ops.json.enc
```

Copy the `openssl` command output by the above command and modify in the .travis-yml

The -out param should be `-out k8s-ops-secret.json`

Create a GitHub machine user according to [these instructions](https://developer.github.com/v3/guides/managing-deploy-keys/#machine-users).

Give this user write permissions to the k8s repo.

Add the GitHub machine user secret key to travis on the app's repo:

```
travis env set --private K8S_OPS_GITHUB_REPO_TOKEN "*****"
```

Commit the .travis.yml changes and the encrypted file.


## Exposing services

Main entrypoint is a [traefik](https://traefik.io/) service, exposed via a load balancer.

Traefik provides application load balancing with path/host-based rules. HTTPS is provided seamlessly using Let's encrypt.

In addition to traefik, the nginx pod can optionally be used on specific service for more advanced use-cases such as auth or caching.


## Static IP for the load balancer

Reserve a static IP:

```
gcloud compute addresses create midburn-ENVIRONMENT_NAME-traefik --region=us-central1
```

Get the static IP address:

```
gcloud compute addresses describe midburn-ENVIRONMENT_NAME-traefik --region=us-central1 | grep ^address:
```

Update in `values.ENVIRONMENT_NAME.yaml`:

```
traefik:
  loadBalancerIP: <THE_STATIC_IP>
```


## Http authentication

HTTP authentication is provided using nginx.

You should configure a traefik backend that points to the nginx pod on a specific port number, then update `nginx-conf.yaml` to handle that port number with http auth enabled.

To add a user to the htpasswd file:

```
htpasswd ./secret-nginx-htpasswd superadmin
```

(use `-c` if you are just creating the file)

set the file as a secret on k8s:

```
kubectl create secret generic nginx-htpasswd --from-file=./secret-nginx-htpasswd
```

Update the value in `values.ENVIRONMENT_NAME.yaml`:

```
nginx:
  htpasswdSecretName: nginx-htpasswd
```


## Authorize with GitHub to push changes

Having infrastructure as code means you should be able to push any changes to infrastructure configuration back to GitHub.

You can use the following procudure on both Google Cloud Shell and from local PC

Create an SSH key -

```
[ ! -f .ssh/id_rsa.pub ] && ssh-keygen -t rsa -b 4096 -C "${USER}@cloudshell"
cat ~/.ssh/id_rsa.pub
```

Add the key in github - https://github.com/settings/keys

Clone the repo

```
git clone git@github.com:midburn/midburn-k8s.git
```



## Delete an environment and related resources

```
helm delete midburn --purge
```
