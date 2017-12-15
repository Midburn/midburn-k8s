# The Midburn Kubernetes Environment

[![Build Status](https://travis-ci.org/Midburn/midburn-k8s.svg?branch=master)](https://travis-ci.org/Midburn/midburn-k8s)

## Why can't it just work all the time?

[![it can - with Kubernetes!](it-can-with-kubernetes.png)](https://cloud.google.com/kubernetes-engine/kubernetes-comic/)

## Interacting with the environment

You can interact with the Kubernetes environment in the following ways - 

* [Google Cloud Shell](https://cloud.google.com/shell/docs/quickstart) - The recommended and easiest way for running management commands. Just setup a Google Cloud account and enable billing (you get 300$ free, you can setup billing alerts to avoid paying by mistake).
* Any modern PC / OS should also work, you will just need to install some basic dependencies like Docker and Google Cloud SDK (possibly more). The main problem with working from local PC is the network connection, if you have a stable, fast connection and know how to install the dependencies, you might be better of running from your own PC.
* Docker + Google Cloud service account - for automation / CI / CD. See the Docker Ops section below for more details.

You can use the cloud shell file editor to edit files, just be sure to configure it to indentation of 2 spaces (not tabs - because they interfere with the yaml files)

## Installation and setup

#### Authorize with Google Cloud

On google cloud shell it's not necessary, your shell is linked to your personal user - any permissions given by any project to your google user will be available.

From local PC run `gcloud auth login` and follow the instructions

#### Authorize with GitHub and clone the k8s repo

Having infrastructure as code means you should be able to push any changes to infrastructure configuration back to GitHub.

You can use the following procudure on both Google Cloud Shell and from local PC

Create an SSH key -

```
[ ! -f .ssh/id_rsa.pub ] && ssh-keygen -t rsa -b 4096 -C "${USER}@cloudshell"
cat ~/.ssh/id_rsa.pub
```

Add the key in github - https://github.com/settings/keys

Clone the midburn-k8s repo

```
git clone git@github.com:midburn/midburn-k8s.git
```

Change to the midburn-k8s directory, all following commands should run from that directory

```
cd midburn-k8s
```

#### Create a new cluster

Creating a new cluster is easiest using the Google Kubernetes Engine UI. It's recommended to start with a minimum of 1 n1-standard-1 node. Need to bear in mind that kubernetes consumes some resources as well.

#### Create a new environment

Each environment should have the following files in the root of the project:

- `.env.ENVIRONMENT_NAME` *(required)*: the basic environment connection details
- `values.ENVIRONMENT_NAME.yaml` *(optional)*: override default helm chart values for this namespace
- `values.ENVIRONMENT_NAME.auto-updated.yaml` *(optional)*: override environment values from automatically updated actions (e.g. continuous deployment)

These files shouldn't contain any secrets and can be committed to a public repo.

#### Connecting to an environment

```
source switch_environment.sh ENVIRONMENT_NAME
```

On cloud shell, if you are mostly using this environment / project, add this to your .bashrc:

```
cd midburn-k8s; source switch_environment.sh ENVIRONMENT_NAME
```

#### Initialize / Upgrade Helm

Installs / upgrades the Helm server-side component on the cluster

```
helm init --upgrade
```

## Releases and deployments

[Helm](https://github.com/kubernetes/helm) manages everything for us.

Kubernetes / Helm have a desired state of the infrastructure and they will do their best to move to that state.

To update the desired state, run:

```
./helm_upgrade.sh
```

Bear in mind that when the command completes it doesn't necesarily mean deployment is complete (although it often does) - it only updates the desired state.

#### Helm upgrade options

You can add arguments to `./helm_upgrade.sh` which are forwarded to the underlying `helm upgrade` command.

Check [the Helm documentation](https://docs.helm.sh/) for more details.

Some useful arguments:

* For initial installation you should add `--install`
* Depending on the changes you might need to add `--recreate-pods` or `--force`
* For debugging you can also use `--debug` and `--dry-run`

Additionally, you can to use `force_update.sh` to force an update on a specific deployment.

#### Helm configuration values

The default values are at `values.yaml` - these are used in the chart template files

Each environment adds or overrides with environment specific settings using `values.ENVIRONMENT_NAME.yaml` which is merged with the `values.yaml` file

Automation scripts can also use the `values.ENVIRONMENT_NAME.auto-updated.yaml` file to update values programatically using the `update_yaml.py` script

## Secrets

Secrets are stored and managed directly in kubernetes and are not managed via Helm.

To update an existing secret, delete it first `kubectl delete secret SECRET_NAME`

After updating a secret you should update the affected deployments, you can use `./force_update.sh` to do that

## Docker OPS

To faciliate CI/CD and other automated flows you can use the provided ops Dockerfile.

The ops container requires a Google Cloud service key:

```
export SERVICE_ACCOUNT_NAME="midburn-k8s-ops"
export SERVICE_ACCOUNT_ID="${SERVICE_ACCOUNT_NAME}@${CLOUDSDK_CORE_PROJECT}.iam.gserviceaccount.com"
gcloud iam service-accounts create "${SERVICE_ACCOUNT_NAME}"
gcloud iam service-accounts keys create "--iam-account=${SERVICE_ACCOUNT_ID}" ./secret-midburn-k8s-ops.json
```

Add admin roles for common services:

```
gcloud projects add-iam-policy-binding --role "roles/storage.admin" "${CLOUDSDK_CORE_PROJECT}" \
                                       --member "serviceAccount:${SERVICE_ACCOUNT_ID}"
gcloud projects add-iam-policy-binding --role "roles/cloudbuild.builds.editor" "${CLOUDSDK_CORE_PROJECT}" \
                                       --member "serviceAccount:${SERVICE_ACCOUNT_ID}"
gcloud projects add-iam-policy-binding --role "roles/container.admin" "${CLOUDSDK_CORE_PROJECT}" \
                                       --member "serviceAccount:${SERVICE_ACCOUNT_ID}"
```

Build and run the ops docker container

```
docker build -t midburn-k8s-ops . &&\
docker run -it -v "`pwd`/secret-midburn-k8s-ops.json:/k8s-ops/secret.json" \
               -v "`pwd`:/ops" \
               midburn-k8s-ops
```

You should be able to run `source switch_environment.sh ENVIRONMENT_NAME` and continue working with the environment from there.

## Continuos Deployment

Each app / module is self-deploying using the ops docker and manages it's own deployment script.

The continuous deployment flow is based on:

* Travis - runs the deployment script on each app's repo on commit to master branch (AKA merge of PR).
* Ops Docker (see above) - provides a consistent deployment environment and to securely authenticate with the service account secret.
* GitHub - for persistency of deployment environment values - GitHub maintains the state of the environment. Each app commits deployment updates to the k8s repo.

We use [Travis CLI](https://github.com/travis-ci/travis.rb#installation) below but you can also do the setup from the UI.

#### Setting up a repo for continuous deployment

Enable Travis for the repo (run `travis enable` from the repo directory)

Copy `.travis.yml` and `continuous_deployment.sh` from this repo to the app repo

Modify the deployment code in continuous_deployment.sh according to your app requirements

Set the k8s ops service account secret on the app's travis:

```
travis encrypt-file ../midburn-k8s/secret-midburn-k8s-ops.json secret-midburn-k8s-ops.json.enc
```

Copy the `openssl` command output by the above command and modify in your continuous_deployment.sh

Modify the -out param of the openssl command to `-out k8s-ops-secret.json`

Create a GitHub machine user according to [these instructions](https://developer.github.com/v3/guides/managing-deploy-keys/#machine-users).

Give this user write permissions to the k8s repo.

Add the GitHub machine user secret key to travis on the app's repo:

```
travis env set --private K8S_OPS_GITHUB_REPO_TOKEN "*****"
```

Commit the .travis.yml changes and the encrypted file.

## App Docker Images

For the above continuous deployment procedure you will also need to build each app docker image automatically.

The easiest way is to add an automated build for the app repo in Google Container Registry, you can do that in the UI

The above example continuous deployment script uses an image which is tagged with the git commit sha

In this case the resulting image tag should look like:

`gcr.io/midburn/spark:GIT_COMMIT_SHA`

Where the tag is the git commit sha

This allows the continuous deployment to update the image tag ASAP without waiting for it to be built.

Kubernetes will make sure the deployment occurs only when the image is ready.

## Exposing services

Main entrypoint is a [traefik](https://traefik.io/) service, exposed via a load balancer.

Traefik provides application load balancing with path/host-based rules. HTTPS is provided seamlessly using Let's encrypt.

In addition to traefik, the nginx pod can optionally be used on specific service for more advanced use-cases such as auth or caching.

#### Static IP for the load balancer

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

#### Http authentication

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
