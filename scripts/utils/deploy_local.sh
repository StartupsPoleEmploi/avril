#!/bin/bash

IF_CHANGE_OPT="--if-change"

if [ "$1" == "$IF_CHANGE_OPT" ]; then
  DEPLOY_IF_CHANGE=true;
  shift;
fi

REPO_NAME=${1?"Usage: deploy_local.sh $IF_CHANGE_OPT <REPO_NAME> <BRANCH_NAME || master>"}
BRANCH_NAME=${2:-master}

declare -A REPO_TO_SERVICE
REPO_TO_SERVICE[avril]=phoenix
REPO_TO_SERVICE[avril-livret1]=nuxt_booklet
REPO_TO_SERVICE[avril-profil]=nuxt_profile

SERVICE_NAME=${REPO_TO_SERVICE[$REPO_NAME]}

if test -z "$SERVICE_NAME"; then
  echo "Wrong <REPO_NAME> : <SERVICE_NAME> not found"
  exit 1;
fi

echo "Pulling $BRANCH_NAME of $REPO_NAME to deploy $SERVICE_NAME..."

cd /home/docker/$REPO_NAME

git fetch --all

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "$BRANCH_NAME" ]; then
  git checkout $BRANCH_NAME
fi

HEADHASH=$(git rev-parse HEAD)
UPSTREAMHASH=$(git rev-parse master@{upstream})

if [[ "$DEPLOY_IF_CHANGE" == "true" && "$HEADHASH" == "$UPSTREAMHASH" ]]; then
  echo "$REPO_NAME hasn't changed, no need to deploy $SERVICE_NAME"
else
  git reset --hard origin/$BRANCH_NAME
  # git pull origin $BRANCH_NAME

  echo "Deploying $SERVICE_NAME..."
  ../avril/scripts/utils/docker_update.sh $SERVICE_NAME
fi