#!/bin/bash

if [ "$1" == "--need-change" ]; then
  ONLY_IF_CHANGES=true;
  shift;
fi

REPO_NAME=${1?"Usage: deploy_local.sh --need-change <REPO_NAME> <BRANCH_NAME || master>"}
BRANCH_NAME=${2:-master}

GIT_PULL_COMMAND="git pull origin $BRANCH_NAME"

if [ "$ONLY_IF_CHANGES" = true ]; then
  GIT_PULL_COMMAND="$GIT_PULL_COMMAND | grep -q -v 'up to date'"
fi

declare -A REPO_TO_SERVICE
REPO_TO_SERVICE[avril]=phoenix
REPO_TO_SERVICE[avril-livret1]=nuxt

SERVICE_NAME=${REPO_TO_SERVICE[$REPO_NAME]}

if test -z "$SERVICE_NAME"; then
  echo "Wrong <REPO_NAME> : <SERVICE_NAME> not found"
  exit 1;
fi

echo "Pulling $BRANCH_NAME of $REPO_NAME to deploy $SERVICE_NAME..."

cd /home/docker/$REPO_NAME

git checkout $BRANCH_NAME

if [[ $(eval $GIT_PULL_COMMAND) ]]; then
  echo "Deploying $SERVICE_NAME..."
  ../avril/scripts/utils/docker_update.sh $SERVICE_NAME
else
  echo "$REPO_NAME hasn't changed, no need to deploy $SERVICE_NAME"
fi