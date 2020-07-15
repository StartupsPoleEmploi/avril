#/bin/bash

do_restore() {
  INSTALLATION_REPO="/home/docker"

  echo "Let's go to $INSTALLATION_REPO"

  if [ ! -d "$INSTALLATION_REPO" ]; then
    echo "$INSTALLATION_REPO doesn't exist. Aborting :(";
    exit 1;
  fi

  echo "Let's clone the sources"
  git clone https://github.com/StartupsPoleEmploi/avril.git && \
  git clone https://github.com/StartupsPoleEmploi/avril-profil.git && \
  git clone https://github.com/StartupsPoleEmploi/avril-livret1.git

  echo "Let's position expected files"

  if [[ -n "$USE_ENV_EXAMPLE" ]] ; then
    cp ./avril/.env.example ./avril/.env
  else
    mv .env ./avril
  fi

  if [[ -n "$DB_DUMP" ]] ; then
    mv DB_DUMP ./avril/db/dumps/latest.dump
  fi

  echo "Let's build Avril container"
  cd avril
  docker-compose build

  echo "Everything went fine! Yai! Simply start the server with:"
  echo ""
  echo "  docker-compose up -d"
}

if [ ! -f .env ]; then
  while true; do
    read -p "Warning: .env file is missing in pwd: $(pwd) \n Do you want to setup the server using .env.example (no API keys)? (y/n)" yn
    case $yn in
        [Yy]* ) USE_ENV_EXAMPLE=true break;;
        [Nn]* ) echo "Move production .env file here and restart this script."; exit 1;;
        * ) echo "Please answer yes or no.";;
    esac
  done
fi

if [ "$#" -ne 1 ]; then
  echo "Usage: restore.sh PATH_TO_DB_DUMP.sql";
  while true; do
    read -p "Warning: you haven't selected a dump file. Do you want to setup the server WITHOUT database initialization? (y/n)" yn
    case $yn in
        [Yy]* ) echo "Let's continue!"; break;;
        [Nn]* ) echo "Restart with: restore.sh PATH_TO_DB_DUMP.sql"; exit 1;;
        * ) echo "Please answer yes or no.";;
    esac
  done
fi

DB_DUMP=$1

while true; do
  read -p "This script will clone Avril sources and setup a new server. Do you want to continue? (y/n)" yn
  case $yn in
      [Yy]* ) do_restore; break;;
      [Nn]* ) echo "Goodbye"; exit 1;;
      * ) echo "Please answer yes or no.";;
  esac
done
