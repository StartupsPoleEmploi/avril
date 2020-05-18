#!/bin/bash

COMMIT_MESSAGE="upgrade avril-shared"

yarn_upgrade() {
  SERVICE_NAME=$1
  ASSET_FOLDER=${2:-.}
  UPGRADE_COMMAND="cd $ASSET_FOLDER && yarn upgrade avril"
  docker-compose exec $SERVICE_NAME bash -c $UPGRADE_COMMAND
}

git_commit_upgrade() {
  ASSET_FOLDER=${1:-.}
  GIT_FOLDER=${2:-.}
  if [[ -n "$GIT_FOLDER" ]]
    then
      GIT_DIR_OPTION="--git-dir=../$GIT_FOLDER/.git"
    else
      # atom ~/.bashrc
  fi
  git $GIT_DIR_OPTION add $ASSET_FOLDER/yarn.lock
  git $GIT_DIR_OPTION commit -m $COMMIT_MESSAGE
  git $GIT_DIR_OPTION push
}

services=(
  phoenix,assets,.
  nuxt_profile,.,avril-profil
  nuxt_booklet,.,avril-booklet
)
for service in "${services[@]}"; do
  IFS=',' read name asset git <<< "${i}"
  echo "Executing $name with $asset and $git"
  # yarn_upgrade $name $asset
  # git_commit_upgrade $asset $git
done