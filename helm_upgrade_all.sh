#!/usr/bin/env bash

source connect.sh

RES=0

echo "Upgrading all charts of ${K8S_ENVIRONMENT_NAME} environment"

! ./helm_upgrade.sh "$@" && echo 'failed helm upgrade' && RES=1;
! ./helm_upgrade_external_chart.sh spark "$@" && echo 'failed spark upgrade' && RES=1;
! ./helm_upgrade_external_chart.sh volunteers "$@" && echo 'failed volunteers upgrade' && RES=1;
! ./helm_upgrade_external_chart.sh bi "$@" && echo 'failed bi upgrade' && RES=1;
! ./helm_upgrade_external_chart.sh profiles "$@" && echo 'failed profiles upgrade' && RES=1;
! ./helm_upgrade_external_chart.sh chatops "$@" && echo 'failed chatops upgrade' && RES=1;
! ./helm_upgrade_external_chart.sh dreams "$@" && echo 'failed dreams upgrade' && RES=1;
! ./helm_upgrade_external_chart.sh camps-index "$@" && echo 'failed camps index upgrade' && RES=1;

exit $RES
