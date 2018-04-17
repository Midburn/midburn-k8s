#!/usr/bin/env bash

source connect.sh

DEFAULT_VALUES_FILE=`[ -f values.yaml ] && echo "-f values.yaml"`
STAGING_AUTO_UPDATED_VALUES_FILE=`[ -f environments/staging/values.auto-updated.yaml ] && echo "-f environments/staging/values.auto-updated.yaml"`
ENVIRONMENT_VALUES_FILE=`[ -f "environments/${K8S_ENVIRONMENT_NAME}/values.yaml" ] && echo "-f environments/${K8S_ENVIRONMENT_NAME}/values.yaml"`
AUTO_UPDATED_VALUES_FILE=`[ -f "environments/${K8S_ENVIRONMENT_NAME}/values.auto-updated.yaml" ] && echo "-f environments/${K8S_ENVIRONMENT_NAME}/values.auto-updated.yaml"`

if [ `./read_yaml.py "environments/${K8S_ENVIRONMENT_NAME}/values.yaml" global enableRootChart` == "true" ]; then
    helm upgrade $DEFAULT_VALUES_FILE \
                 $STAGING_AUTO_UPDATED_VALUES_FILE \
                 $ENVIRONMENT_VALUES_FILE \
                 $AUTO_UPDATED_VALUES_FILE "${K8S_HELM_RELEASE_NAME}-${K8S_ENVIRONMENT_NAME}" . "$@" \
        && echo "Chart upgraded successfully"
else
    echo "root chart is disabled, skipping helm upgrade"
fi
