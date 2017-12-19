#!/usr/bin/env bash

source connect.sh

if [ "${1}" == "" ]; then
    echo "Usage: ./helm_update_values.sh <YAML_OVERRIDE_VALUES_JSON> [GIT_COMMIT_MESSAGE] [GIT_REPO_TOKEN] [GIT_REPO_SLUG] [GIT_REPO_BRANCH]"
fi

YAML_OVERRIDE_VALUES_JSON="${1}"
GIT_COMMIT_MESSAGE="${2}"
GIT_REPO_TOKEN="${3}"
GIT_REPO_SLUG="${4}"
GIT_REPO_BRANCH="${5:-master}"

if [ "${YAML_OVERRIDE_VALUES_JSON:0:1}" != '{' ]; then
    ! YAML_OVERRIDE_VALUES_JSON=`echo "${YAML_OVERRIDE_VALUES_JSON}" | base64 -d` \
        && echo "failed to decode the override values" && exit 1
fi

[ "${YAML_OVERRIDE_VALUES_JSON:0:1}" != '{' ] && echo "invalid override values" && exit 1

echo "Updating values for ${K8S_ENVIRONMENT_NAME} environment: ${YAML_OVERRIDE_VALUES_JSON}"

! ./update_yaml.py "${YAML_OVERRIDE_VALUES_JSON}" "environments/${K8S_ENVIRONMENT_NAME}/values.auto-updated.yaml" &&\
    echo "Failed to update environments/${K8S_ENVIRONMENT_NAME}/values.auto-updated.yaml" && exit 1

if [ "${GIT_COMMIT_MESSAGE}" != "" ] && [ "${GIT_REPO_TOKEN}" != "" ] && [ "${GIT_REPO_SLUG}" != "" ]; then
    echo "Committing and pushing to Git"
    TEMPDIR=`mktemp -d`

    ! (
        git config user.email "deployment-bot@${K8S_ENVIRONMENT_NAME}" &&
        git config user.name "${K8S_ENVIRONMENT_NAME}-deployment-bot"
    ) && echo "failed to git config" && exit 1

    ! git clone --depth 1 --branch "${GIT_REPO_BRANCH}" "https://github.com/${GIT_REPO_SLUG}.git" "${TEMPDIR}" \
      && echo "failed git clone" && exit 1

    if ! git diff --shortstat --exit-code "environments/${K8S_ENVIRONMENT_NAME}/values.auto-updated.yaml"; then
        echo "Committing and pushing changes in environments/${K8S_ENVIRONMENT_NAME}/values.auto-updated.yaml"
        ! (
            git add "environments/${K8S_ENVIRONMENT_NAME}/values.auto-updated.yaml" &&\
            git commit -m "${GIT_COMMIT_MESSAGE}" &&\
            git push https://${GIT_REPO_TOKEN}'@'github.com/${GIT_REPO_SLUG}.git "${GIT_REPO_BRANCH}"
        ) && echo "failed to push changes" && exit 1
    else
        echo "No changes, skipping commit / push"
    fi
    rm -rf "${TEMPDIR}"
fi

echo "Great Success!"
exit 0
