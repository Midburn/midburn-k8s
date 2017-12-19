#!/usr/bin/env bash

#
# Run CI / automation scripts within the docker ops container
#
# File can be downloaded and executed directly, assuming you have secret-midburn-k8s-ops.json available in current directory
#
# wget https://raw.githubusercontent.com/Midburn/midburn-k8s/master/run_docker_ops.sh && chmod +x run_docker_ops.sh
# ./run_docker_ops.sh "staging" "kubectl get pods"
#

usage() {
    echo "Usage: ./run_docker_ops.sh <ENVIRONMENT_NAME> [SCRIPT] [OPS_DOCKER_IMAGE] [OPS_REPO_SLUG] [OPS_REPO_BRANCH] [OPS_SECRET_JSON_FILE] [DOCKER_RUN_PARAMS]"
}

ENVIRONMENT_NAME="${1}"
SCRIPT="${2}"
OPS_DOCKER_IMAGE="${3}"
OPS_REPO_SLUG="${4}"
OPS_REPO_BRANCH="${5}"
OPS_SECRET_JSON_FILE="${6}"
DOCKER_RUN_PARAMS="${7}"

echo "ENVIRONMENT_NAME=${ENVIRONMENT_NAME}"
echo "OPS_DOCKER_IMAGE=${OPS_DOCKER_IMAGE}"
echo "OPS_REPO_SLUG=${OPS_REPO_SLUG}"
echo "OPS_REPO_BRANCH=${OPS_REPO_BRANCH}"
echo "OPS_SECRET_JSON_FILE=${OPS_SECRET_JSON_FILE}"
echo "DOCKER_RUN_PARAMS=${DOCKER_RUN_PARAMS}"

[ -z "${ENVIRONMENT_NAME}" ] && usage && exit 1

[ -z "${SCRIPT}" ] && SCRIPT="bash"
[ -z "${OPS_DOCKER_IMAGE}" ] && OPS_DOCKER_IMAGE="orihoch/midburn-k8s@sha256:95f0cb600504dd891aa8a4dba25aef63091984da27d0c3072085673665fb4cd6"
[ -z "${OPS_REPO_SLUG}" ] && OPS_REPO_SLUG="Midburn/midburn-k8s"
[ -z "${OPS_REPO_BRANCH}" ] && OPS_REPO_BRANCH="master"
[ -z "${OPS_SECRET_JSON_FILE}" ] && OPS_SECRET_JSON_FILE="`pwd`/secret-midburn-k8s-ops.json"

[ ! -f "${OPS_SECRET_JSON_FILE}" ] && echo "Missing secret json file ${OPS_SECRET_JSON_FILE}" && exit 1

if [ "${OPS_REPO_SLUG}" == "." ]; then
    echo "Using current directory as the source ops repository"
    OPS_REPO_DIR=`pwd`
else
    OPS_REPO_DIR=`mktemp -d`
    echo "Cloning ops repo from https://github.com/${OPS_REPO_SLUG}.git branch ${OPS_REPO_BRANCH} to ${OPS_REPO_DIR}"
    ! git clone --depth 1 --branch "${OPS_REPO_BRANCH}" "https://github.com/${OPS_REPO_SLUG}.git" "${OPS_REPO_DIR}" \
        && echo "failed to clone k8s repo" && exit 1
fi

if [ "${OPS_DOCKER_IMAGE}" == "." ]; then
    echo "Building ops docker image from current directory"
    OPS_DOCKER_IMAGE="midburn-k8s"
    docker build -t "${OPS_DOCKER_IMAGE}" .
else
    echo "Pulling ops docker image ${OPS_DOCKER_IMAGE}"
    ! docker pull "${OPS_DOCKER_IMAGE}" \
        && echo "failed to pull ops docker image" && exit 1
fi

! docker run -it -v "${OPS_SECRET_JSON_FILE}:/k8s-ops/secret.json" \
                 -v "${OPS_REPO_DIR}:/ops" \
                 $DOCKER_RUN_PARAMS \
                 "${OPS_DOCKER_IMAGE}" \
                 -c "source ~/.bashrc && source switch_environment.sh ${ENVIRONMENT_NAME}; ${SCRIPT}" \
    && echo "failed to run SCRIPT" && exit 1

echo "Great Success!"
exit 0
