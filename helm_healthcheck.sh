#!/usr/bin/env bash

source connect.sh

RES=0

echo "Performing health checks for all charts of ${K8S_ENVIRONMENT_NAME} environment"

root_healthcheck() {
    ! [ "`./read_env_yaml.sh global enableRootChart`" == "true" ] \
        && echo "root chart is disabled, skipping healthcheck" && return 0
    kubectl rollout status deployment/adminer --watch=false &&\
    kubectl rollout status deployment/nginx --watch=false &&\
    kubectl rollout status deployment/traefik --watch=false
}

spark_healthcheck() {
    ! [ "`./read_env_yaml.sh spark enabled`" == "true" ] \
        && echo "spark is disabled, skipping healthcheck" && return 0
    kubectl rollout status deployment/spark --watch=false &&\
    kubectl rollout status deployment/sparkdb --watch=false
}

volunteers_healthcheck() {
    ! [ "`./read_env_yaml.sh volunteers enabled`" == "true" ] \
        && echo "volunteers is disabled, skipping healthcheck" && return 0
    kubectl rollout status deployment/volunteers --watch=false &&\
    kubectl rollout status deployment/volunteersdb --watch=false

}

bi_healthcheck() {
    ! [ "`./read_env_yaml.sh bi enabled`" == "true" ] \
        && echo "bi is disabled, skipping healthcheck" && return 0
    kubectl rollout status deployment/metabase --watch=false

}

profiles_healthcheck() {
    ! [ "`./read_env_yaml.sh profiles enabled`" == "true" ] \
        && echo "profiles is disabled, skipping healthcheck" && return 0
    kubectl rollout status deployment/profiles-drupal --watch=false &&\
    kubectl rollout status deployment/profiles-db --watch=false
}

chatops_healthcheck() {
    ! [ "`./read_env_yaml.sh chatops enabled`" == "true" ] \
        && echo "chatops is disabled, skipping healthcheck" && return 0
    kubectl rollout status deployment/chatops --watch=false
}

dreams_healthcheck() {
    ! [ "`./read_env_yaml.sh dreams enabled`" == "true" ] \
        && echo "dreams is disabled, skipping healthcheck" && return 0
    kubectl rollout status deployment/dreams --watch=false
}

! root_healthcheck && echo failed root healthcheck && RES=1;
! spark_healthcheck && echo failed spark healthcheck && RES=1;
! volunteers_healthcheck && echo failed volunteers healthcheck && RES=1;
! bi_healthcheck && echo failed bi healthcheck && RES=1;
! profiles_healthcheck && echo failed profiles healthcheck && RES=1;
! chatops_healthcheck && echo failed chatops healthcheck && RES=1;
! dreams_healthcheck && echo failed dreams healthcheck && RES=1;

[ "${RES}" == "0" ] && echo Great Success!

exit $RES
