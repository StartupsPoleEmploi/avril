#!/bin/bash
# wait-for-postgres.sh

set -e
LOCK_FILE="init.lock"

cmd="$@"

cd "$(dirname "$0")"

until [[ ! -f $LOCK_FILE ]]; do
  >&2 echo "[WAIT] DB init is in process"
  sleep 1
done

>&2 echo "[DONE] Finished init"

exit 0