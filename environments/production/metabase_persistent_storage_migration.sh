#!/usr/bin/env bash

source switch_environment.sh production

gcloud compute ssh midburn-k8s-persistent-storage-vm --command="bash -c '
    mkdir -p /data/${K8S_ENVIRONMENT_NAME}
    ! mkdir /data/${K8S_ENVIRONMENT_NAME}/metabase && echo failed to create metabase dir && exit 1
    echo setting permissions
    sudo chown -R root:root /data/${K8S_ENVIRONMENT_NAME}/metabase
    echo great success
    exit 0
'"
