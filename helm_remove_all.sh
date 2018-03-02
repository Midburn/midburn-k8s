#!/usr/bin/env bash

source connect.sh

RES=0

echo "Removing all charts of ${K8S_ENVIRONMENT_NAME} environment"

[ "${1}" != "--approve" ] && read -p 'Press <Enter> to continue...'

! helm delete --purge "${K8S_HELM_RELEASE_NAME}-${K8S_ENVIRONMENT_NAME}" && RES=1
! helm delete --purge "${K8S_HELM_RELEASE_NAME}-spark-${K8S_ENVIRONMENT_NAME}" && RES=1
! helm delete --purge "${K8S_HELM_RELEASE_NAME}-volunteers-${K8S_ENVIRONMENT_NAME}" && RES=1
! helm delete --purge "${K8S_HELM_RELEASE_NAME}-bi-${K8S_ENVIRONMENT_NAME}" && RES=1
! helm delete --purge "${K8S_HELM_RELEASE_NAME}-profiles-${K8S_ENVIRONMENT_NAME}" && RES=1
! helm delete --purge "${K8S_HELM_RELEASE_NAME}-chatops-${K8S_ENVIRONMENT_NAME}" && RES=1
! helm delete --purge "${K8S_HELM_RELEASE_NAME}-dreams-${K8S_ENVIRONMENT_NAME}" && RES=1
! helm delete --purge "${K8S_HELM_RELEASE_NAME}-camps-index-${K8S_ENVIRONMENT_NAME}" && RES=1

exit $RES
