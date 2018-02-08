#!/usr/bin/env bash

source switch_environment.sh staging

VOLUNTEERSDB_POD=`kubectl get pods | grep volunteersdb- | cut -d" " -f1 -`
[ -z "${VOLUNTEERSDB_POD}" ] && echo "failed to get volunteersdb pod name" && exit 1

echo "deleting existing volunteersdb data from persistent storage (if there is any)"
read -p "press <Enter> to continue"
! gcloud compute ssh midburn-k8s-persistent-storage-vm --command="bash -c 'sudo rm -rf /data/${K8S_ENVIRONMENT_NAME}/volunteersdb'" && echo failed && exit 1

echo "deleting volunteersdb service for a clean migration"
read -p "press <Enter> to continue"
! kubectl delete service volunteersdb && echo failed && exit 1

echo "creating storage and importing data from pod"
gcloud compute ssh midburn-k8s-persistent-storage-vm --command="bash -c '
    mkdir -p /data/${K8S_ENVIRONMENT_NAME}
    ! mkdir /data/${K8S_ENVIRONMENT_NAME}/volunteersdb && echo failed to create volunteersdb dir && exit 1
    cd
    ! [ -e midburn-k8s ] && git clone https://github.com/Midburn/midburn-k8s.git
    cd midburn-k8s
    ! (git checkout master && git pull origin master) && echo failed && exit 1
    source switch_environment.sh ${K8S_ENVIRONMENT_NAME}
    echo copying from pod ${VOLUNTEERSDB_POD}
    ! kubectl cp ${VOLUNTEERSDB_POD}:/data/db /data/${K8S_ENVIRONMENT_NAME}/volunteersdb && echo failed && exit 1
    echo setting permissions
    sudo chown -R root:root /data/${K8S_ENVIRONMENT_NAME}/volunteersdb
    echo great success
    exit 0
'"

echo "redeploying volunteers chart to enable the service via the new storage setup"
./helm_upgrade_external_chart.sh volunteers
