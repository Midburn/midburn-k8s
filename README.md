# The Midburn Kubernetes Environment


## Why can't it just work all the time?

[![it can - with Kubernetes!](it-can-with-kubernetes.png)](https://cloud.google.com/kubernetes-engine/kubernetes-comic/)


## Interacting with the environment

You can interact with the Kubernetes environment in the following ways - 

* [Google Cloud Shell](https://cloud.google.com/shell/docs/quickstart) - The recommended and easiest way for running management commands. Just setup a Google Cloud account and enable billing (you get 300$ free, you can setup billing alerts to avoid paying by mistake).
* Any modern PC / OS should also work, you will just need to install some basic dependencies like Docker and Google Cloud SDK (possibly more). The main problem with working from local PC is the network connection, if you have a stable, fast connection and know how to install the dependencies, you might be better of running from your own PC.
* Docker + Google Cloud service account - for automation / CI / CD. See the Docker Ops section below for more details.

You can use the cloud shell file editor to edit files, just be sure to configure it to indentation of 2 spaces (not tabs - because they interfere with the yaml files)


## Initial installation and setup

Install [Google Cloud SDK](https://cloud.google.com/sdk/) and run `gcloud auth login` (not necessary on Google Cloud Shell).

Clone the repo

```
git clone https://github.com/Midburn/midburn-k8s.git
```

All following commands should run from the midburn-k8s directory

```
cd midburn-k8s
```


## Connect to an existing environment

The main midburn environments should be committed to this repo, each environment has a corresponding `.env.ENVIRONMENT_NAME` file

```
source switch_environment.sh ENVIRONMENT_NAME
```


## Releases and deployments

[Helm](https://github.com/kubernetes/helm) manages everything for us.

Make sure you have the latest helm installed on both client and server: `helm init --upgrade`

Deploy:

```
./helm_upgrade.sh
```

Bear in mind that when the command completes it doesn't necesarily mean deployment is complete (although it often does) - it only updates the desired state.

Kubernetes / Helm have a desired state of the infrastructure and they will do their best to move to that state.

You can add arguments to `./helm_upgrade.sh` which are forwarded to the underlying `helm upgrade` command.

Check [the Helm documentation](https://docs.helm.sh/) for more details.

Some useful arguments:

* For initial installation you should add `--install`
* Depending on the changes you might need to add `--recreate-pods` or `--force`
* For debugging you can also use `--debug` and `--dry-run`

Additionally, you can to use `force_update.sh` to force an update on a specific deployment.


## Helm configuration values

The default values are at `values.yaml` - these are used in the chart template files (under `templates` directory)

Each environment can override these values using `values.ENVIRONMENT_NAME.yaml`

Finally, automation scripts write values to `values.ENVIRONMENT_NAME.auto-updated.yaml` using the `update_yaml.py` script


## Secrets

Secrets are stored and managed directly in kubernetes and are not managed via Helm.

To update an existing secret, delete it first `kubectl delete secret SECRET_NAME`

After updating a secret you should update the affected deployments, you can use `./force_update.sh` to do that

All secrets are optional so you can run the environment without any secretes and will use default values similar to dev environments.


## Create a new environment

Each environment should have the following files in the root of the project:

- `.env.ENVIRONMENT_NAME` *(required)*: the basic environment connection details
- `values.ENVIRONMENT_NAME.yaml` *(optional)*: override default helm chart values for this namespace
- `values.ENVIRONMENT_NAME.auto-updated.yaml` *(optional)*: override environment values from automatically updated actions (e.g. continuous deployment)

These files shouldn't contain any secrets and can be committed to a public repo.

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
