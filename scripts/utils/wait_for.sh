#!/bin/bash
# wait-for-postgres.sh

set -e
LOCK_FILE="db/$1.lock"

cmd="$@"

cd "$(dirname "$0")/.."

echo "[INIT] check $1 status"

until [[ ! -f $LOCK_FILE ]]; do
  >&2 echo "[WAIT] $1 is in process"
  sleep 1
done

>&2 echo "[DONE] Finished $1"

exit 0