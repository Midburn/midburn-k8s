#!/usr/bin/env bash

source switch_environment.sh staging

echo "deleting existing volunteersdb data from persistent storage (if there is any)"
read -p "press <Enter> to continue"
! gcloud compute ssh midburn-k8s-persistent-storage-vm --command="bash -c 'sudo rm -rf /data/${K8S_ENVIRONMENT_NAME}/volunteersdb'" && echo failed && exit 1

echo "creating storage"
gcloud compute ssh midburn-k8s-persistent-storage-vm --command="bash -c '
    mkdir -p /data/${K8S_ENVIRONMENT_NAME}
    ! mkdir /data/${K8S_ENVIRONMENT_NAME}/volunteersdb && echo failed to create volunteersdb dir && exit 1
    echo setting permissions
    sudo chown -R root:root /data/${K8S_ENVIRONMENT_NAME}/volunteersdb
    echo great success
    exit 0
'"
