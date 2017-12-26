#!/usr/bin/env bash

usage() {
    echo "Usage: ./helm_upgrade_chart.sh <CHART_NAME>"
}

CHART_NAME="${1}"

[ -z "${CHART_NAME}" ] && usage && exit 1

RELEASE_NAME="${CHART_NAME}-${K8S_ENVIRONMENT_NAME}"
CHART_DIRECTORY="charts/${CHART_NAME}"

source connect.sh

echo "RELEASE_NAME=${RELEASE_NAME}"
echo "CHART_DIRECTORY=${CHART_DIRECTORY}"

[ ! -e "${CHART_DIRECTORY}" ] && echo "CHART_DIRECTORY does not exist" && exit 1

TEMPDIR=`mktemp -d`
echo '{}' > "${TEMPDIR}/values.yaml"

for VALUES_FILE in values.yaml environments/${K8S_ENVIRONMENT_NAME}/values.yaml environments/${K8S_ENVIRONMENT_NAME}/values.auto-updated.yaml
do
    if [ -f "${VALUES_FILE}" ]; then
        GLOBAL_VALUES=`./read_yaml.py "${VALUES_FILE}" global 2>/dev/null`
        ! [ -z "${GLOBAL_VALUES}" ] \
            && ./update_yaml.py '{"global":'${GLOBAL_VALUES}'}' "${TEMPDIR}/values.yaml"
        RELEASE_VALUES=`./read_yaml.py "${VALUES_FILE}" "${CHART_NAME}" 2>/dev/null`
        ! [ -z "${RELEASE_VALUES}" ] \
            && ./update_yaml.py "${RELEASE_VALUES}" "${TEMPDIR}/values.yaml"
    fi
#    cat "${TEMPDIR}/values.yaml"
done

helm upgrade -f "${TEMPDIR}/values.yaml" "${RELEASE_NAME}" "${CHART_DIRECTORY}" "${@:2}"

rm -rf $TEMPDIR
