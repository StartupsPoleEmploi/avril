#!/bin/bash

CPT=0;
DATE=$(date +%T)

while true; do
  CPT=$((CPT+1))
  PREVIOUS_OUTPUT="$AVRIL_OUTPUT-$NUXT_OUTPUT"
  AVRIL_OUTPUT=$(curl --max-time 0,5 --fail -s -o /dev/null -I -w "%{http_code}" localhost/healthcheck)
  NUXT_OUTPUT=$(curl --max-time 0,5 --fail -s -o /dev/null -I -w "%{http_code}" localhost/ma-candidature-vae/hotjar)
  ECHO_OUTPUT="Test #$CPT: Avril: $AVRIL_OUTPUT - Nuxt: $NUXT_OUTPUT"

  if [ $CPT -eq 1 ] || [ "$AVRIL_OUTPUT-$NUXT_OUTPUT" == "$PREVIOUS_OUTPUT" ]; then
    printf "\r$ECHO_OUTPUT since $DATE";
  else
    DATE=$(date +%T)
    printf "\n$ECHO_OUTPUT since $DATE";
  fi

  sleep 0.5
done