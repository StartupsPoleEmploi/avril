#!/bin/bash

CPT=0;

while true; do
  AVRIL_OUTPUT=$(curl --fail -s -o /dev/null -I -w "%{http_code}" localhost:4000)
  NUXT_OUTPUT=$(curl --fail -s -o /dev/null -I -w "%{http_code}" localhost:4000/ma-candidature-vae/hotjar)
  CPT=$((CPT+1))
  if [ "$AVRIL_OUTPUT-$NUXT_OUTPUT" == "200-200" ]; then
    echo -ne "Test #$CPT: OK => Avril: $AVRIL_OUTPUT - Nuxt: $NUXT_OUTPUT\r";
  else
    echo "Test #$CPT: KO => Avril: $AVRIL_OUTPUT - Nuxt: $NUXT_OUTPUT";
  fi

  sleep 0.5
done