#!/usr/bin/env bash

source switch_environment.sh production

SPARKDB_POD=`kubectl get pods | grep sparkdb- | cut -d" " -f1 -`
[ -z "${SPARKDB_POD}" ] && echo "failed to get sparkdb pod name" && exit 1

echo "deleting existing sparkdb data from persistent storage (if there is any)"
read -p "press <Enter> to continue"
! gcloud compute ssh midburn-k8s-persistent-storage-vm --command="bash -c 'sudo rm -rf /data/${K8S_ENVIRONMENT_NAME}/sparkdb'" && echo failed && exit 1

echo "deleting sparkdb service for a clean migration"
read -p "press <Enter> to continue"
! kubectl delete service sparkdb && echo failed && exit 1

echo "creating storage and importing data from pod"
gcloud compute ssh midburn-k8s-persistent-storage-vm --command="bash -c '
    mkdir -p /data/${K8S_ENVIRONMENT_NAME}
    ! mkdir /data/${K8S_ENVIRONMENT_NAME}/sparkdb && echo failed to create sparkdb dir && exit 1
    cd
    ! [ -e midburn-k8s ] && git clone https://github.com/Midburn/midburn-k8s.git
    cd midburn-k8s
    ! (git checkout master && git pull origin master) && echo failed && exit 1
    source switch_environment.sh ${K8S_ENVIRONMENT_NAME}
    echo copying from pod ${SPARKDB_POD}
    ! kubectl cp ${SPARKDB_POD}:/var/lib/mysql /data/${K8S_ENVIRONMENT_NAME}/sparkdb && echo failed && exit 1
    echo setting permissions
    sudo chown -R root:root /data/${K8S_ENVIRONMENT_NAME}/sparkdb
    echo great success
    exit 0
'"

echo "redeploying spark chart to enable the service via the new storage setup"
./helm_upgrade_external_chart.sh spark
