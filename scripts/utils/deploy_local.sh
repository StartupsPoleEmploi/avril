#!/bin/bash

REPO_NAME=${1?"Usage: deploy <REPO_NAME> <BRANCH_NAME || master>"}
BRANCH_NAME=${2:-master}

declare -A REPO_TO_SERVICE
REPO_TO_SERVICE[avril]=phoenix
REPO_TO_SERVICE[avril-livret1]=nuxt

SERVICE_NAME=${REPO_TO_SERVICE[$REPO_NAME]}

if test -z "$SERVICE_NAME"; then
  echo "Wrong <REPO_NAME> : <SERVICE_NAME> not found"
  exit 1;
fi

echo "Pulling $BRANCH_NAME of $REPO_NAME to update $SERVICE_NAME"

cd /home/docker/$REPO_NAME

git checkout $BRANCH_NAME
git pull origin $BRANCH_NAME

../avril/scripts/utils/docker_update.sh $SERVICE_NAME