#/bin/bash

move_if_file() {
  FILENAME=$1
  DESTINATION=$2

  if [ -f "$FILENAME" ]; then
    mv $FILENAME $DESTINATION
  else
    echo "Warning: $FILENAME not present: ignoring"
  fi
}

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

  if [ -n "$USE_ENV_EXAMPLE" ] ; then
    cp ./avril/.env.example ./avril/.env
  else
    mv .env ./avril
  fi

  move_if_file $DB_DUMP ./avril/db/dumps/latest.dump
  move_if_file docker-compose.override.yml ./avril

  mkdir -p /root/ssl/avril.pole-emploi.fr
  move_if_file avril.pole-emploi.fr.crt /root/ssl/avril.pole-emploi.fr
  move_if_file entrust-avril.pole-emploi.fr-key.pem /root/ssl/avril.pole-emploi.fr

  echo "Let's build Avril container"
  cd avril
  docker-compose build

  echo "Everything went fine! Yai! Simply start the server with:"
  echo ""
  echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
  echo "cd avril && docker-compose up -d"
  echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
}

if [ ! -f .env ]; then
  while true; do
    read -p "Warning: .env file is missing in pwd: $(pwd) \n Do you want to setup the server using .env.example (no API keys)? (y/n) " yn
    case $yn in
        [Yy]* ) USE_ENV_EXAMPLE="true" break;;
        [Nn]* ) echo "Move production .env file here and restart this script."; exit 1;;
        * ) echo "Please answer yes or no.";;
    esac
  done
fi

if [ "$#" -ne 1 ]; then
  echo "Usage: restore.sh PATH_TO_DB_DUMP.dump";
  while true; do
    read -p "Warning: you haven't selected a dump file. Do you want to setup the server WITHOUT database initialization? (y/n) " yn
    case $yn in
        [Yy]* ) echo "Let's continue!"; break;;
        [Nn]* ) echo "Restart with: restore.sh PATH_TO_DB_DUMP.dump"; exit 1;;
        * ) echo "Please answer yes or no.";;
    esac
  done
fi

DB_DUMP=$1

while true; do
  read -p "This script will clone Avril sources and setup a new server. Do you want to continue? (y/n) " yn
  case $yn in
      [Yy]* ) do_restore; break;;
      [Nn]* ) echo "Goodbye"; exit 1;;
      * ) echo "Please answer yes or no.";;
  esac
done
