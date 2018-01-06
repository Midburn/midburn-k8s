#!/usr/bin/env bash

source connect.sh

DEFAULT_VALUES_FILE=`[ -f values.yaml ] && echo "-f values.yaml"`
ENVIRONMENT_VALUES_FILE=`[ -f "environments/${K8S_ENVIRONMENT_NAME}/values.yaml" ] && echo "-f environments/${K8S_ENVIRONMENT_NAME}/values.yaml"`
AUTO_UPDATED_VALUES_FILE=`[ -f "environments/${K8S_ENVIRONMENT_NAME}/values.auto-updated.yaml" ] && echo "-f environments/${K8S_ENVIRONMENT_NAME}/values.auto-updated.yaml"`

helm upgrade $DEFAULT_VALUES_FILE $ENVIRONMENT_VALUES_FILE $AUTO_UPDATED_VALUES_FILE "${K8S_HELM_RELEASE_NAME}-${K8S_ENVIRONMENT_NAME}" . "$@"
