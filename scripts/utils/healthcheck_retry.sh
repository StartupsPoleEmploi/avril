#!/bin/bash

HEALTHCHECK_FILE="/root/.healthcheck"

echo "Healthcheck start";

if [ -r "$HEALTHCHECK_FILE" ]; then
  LAST_HEALTHCHECK=$(date -r "$HEALTHCHECK_FILE" +%s)
  FIVE_MINUTES_AGO=$(date -d 'now - 5 minutes' +%s)
  echo "Healthcheck file present";
  if (( $LAST_HEALTHCHECK <= $FIVE_MINUTES_AGO )); then
    touch $HEALTHCHECK_FILE;
    echo "Healthcheck file updated";
    exit 0;
  fi
fi

curl --fail -sS http://127.0.0.1:${PORT:-80} || exit 1;

if [ $? -eq 0 ]; do
  touch $HEALTHCHECK_FILE;
  echo "Healthcheck file created";
fi