#!/bin/bash

yarn_upgrade() {
  SERVICE_NAME=$1
  ASSET_FOLDER=${2:-.}
  docker-compose exec $SERVICE_NAME bash -c "cd $ASSET_FOLDER && yarn upgrade avril"
}

git_commit_upgrade() {
  ASSET_FOLDER=${1:-.}
  GIT_FOLDER=${2:-avril}
  if [[ -n "$GIT_FOLDER" ]] ; then
    GIT_DIR_OPTION="--git-dir=../$GIT_FOLDER/.git";
  fi
  git $GIT_DIR_OPTION add $ASSET_FOLDER/yarn.lock
  git $GIT_DIR_OPTION commit -m "upgrade avril-shared"
  git $GIT_DIR_OPTION push
}

services=(
  phoenix,assets
  nuxt_profile,.,avril-profil
  nuxt_booklet,.,avril-livret1
)
for service in "${services[@]}"; do
  IFS=',' read name asset git <<< "${service}"
  echo "Executing $name with $asset and $git"

  yarn_upgrade $name $asset
  git_commit_upgrade $asset $git
done