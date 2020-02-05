#!/bin/sh

HEALTHCHECK_FILE="/root/.healthchecked"

COMMAND=${*?"Usage: healthcheck_retry <COMMAND>"}

if [ -r "$HEALTHCHECK_FILE" ]; then
  LAST_HEALTHCHECK=$(date -r "$HEALTHCHECK_FILE" +%s)
  # FIVE_MINUTES_AGO=$(date -d 'now - 5 minutes' +%s)
  FIVE_MINUTES_AGO=$(echo "$(( $(date +%s)-5*60 ))")
  echo "Healthcheck file present";
  # if (( $LAST_HEALTHCHECK > $FIVE_MINUTES_AGO )); then
  if [ $LAST_HEALTHCHECK -gt $FIVE_MINUTES_AGO ]; then
    echo "Healthcheck too recent";
    exit 0;
  fi
fi

if $COMMAND ; then
  echo "\"$COMMAND\" succeed: updating file";
  touch $HEALTHCHECK_FILE;
  exit 0;
else
  echo "\"$COMMAND\" failed: exiting";
  exit 1;
fi