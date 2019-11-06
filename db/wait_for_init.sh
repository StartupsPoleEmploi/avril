#!/bin/bash
# wait-for-postgres.sh

set -e
LOCK_FILE="init.lock"

cmd="$@"

until [[ ! -f $LOCK_FILE ]]; do
  >&2 echo "DB init is in process - sleeping"
  sleep 1
done

>&2 echo "Finished init - executing command"
exec $cmd