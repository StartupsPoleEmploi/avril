#!/bin/bash

export PGPASSWORD=$POSTGRES_PASSWORD

DUMP_FILE="/docker-entrypoint-initdb.d/latest.dump"

createdb -h $POSTGRES_HOST -U $POSTGRES_USER -W $POSTGRES_DB

if [[ -f $DUMP_FILE ]]; then
  pg_restore --verbose --clean --create --no-acl --no-owner -h $POSTGRES_HOST -d $POSTGRES_DB -U $POSTGRES_USER -W $DUMP_FILE
else
  echo "Dump file $DUMP_FILE not found"
  echo $(pwd)
fi