#!/usr/bin/env bash

IMPORT_SUFFIX="${1}"
[ -z "${IMPORT_SUFFIX}" ] && echo "Usage: charts-external/spark/recreate_db.sh IMPORT_SUFFIX" && exit 1

echo "Recreating DB for ${K8S_ENVIRONMENT_NAME} environment"
[ "${ARE_YOU_SURE}" != "yes" ] && read -p "DANGER! All data in DB will be lost! Press <Enter> to continue"

TEMPDIR=`mktemp -d`
JOB_SUFFIX=`date +%Y%m%d%H%M%S`

IMPORT_URL="gs://midburn-k8s-backups/sparkdb-staging-dump-${IMPORT_SUFFIX}.sql"

echo 'apiVersion: batch/v1
kind: Job
metadata:
  name: sparkdb-import-'${JOB_SUFFIX}'
spec:
  template:
    metadata:
      name: sparkdb-import-'${JOB_SUFFIX}'
    spec:
      containers:
      - name: sparkdb-import-'${JOB_SUFFIX}'
        image: orihoch/sk8s-ops:mysql
        resources: {"requests": {"cpu": "100m", "memory": "400Mi"}, "limits": {"cpu": "300m", "memory": "800Mi"}}
        command:
        - bash
        - "-c"
        - |
          [ -z "${IMPORT_URL}" ] && echo "Missing IMPORT_URL" && exit 1;
          [ -z "${MYSQL_ROOT_PASSWORD}" ] && echo "Missing MYSQL_ROOT_PASSWORD" && exit 1;
          ! gsutil cp "${IMPORT_URL}" /import.sql && echo "Failed to download IMPORT_URL: ${IMPORT_URL}" && exit 1;
          ! ls -lah /import.sql && exit 1;
          mysql_exec(){
            mysql --host=sparkdb --port=3306 --protocol=tcp --user=root \
                                 "--password=${MYSQL_ROOT_PASSWORD}" "$@"
          };
          echo "DROP DATABASE spark;" | mysql_exec;
          cat /import.sql | mysql_exec;
          echo "Great Success!";
          exit 0;
        env:
        - name: IMPORT_URL
          value: "'$IMPORT_URL'"
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: sparkdb-root
              key: MYSQL_ROOT_PASSWORD
      restartPolicy: Never
' > $TEMPDIR/job.yaml

kubectl create -f $TEMPDIR/job.yaml

rm -rf $TEMPDIR

while ! kubectl get job sparkdb-import-${JOB_SUFFIX}; do
    sleep 2
    printf .
done
echo
while true; do
    POD_NAME=`kubectl get pods | grep sparkdb-import-20180220- | grep ' Running ' | cut -d" " -f1 -`
    ! [ -z "${POD_NAME}" ] && break
    sleep 5
done

sleep 10
kubectl logs "${POD_NAME}"

exit 0
