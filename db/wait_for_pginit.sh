#!/bin/bash
# wait-for-postgres.sh

set -e
LOCK_FILE="pginit.lock"

cmd="$@"

cd "$(dirname "$0")"

echo "[INIT] check pginit status"

until [[ ! -f $LOCK_FILE ]]; do
  >&2 echo "[WAIT] pginit is in process"
  sleep 1
done

>&2 echo "[DONE] Finished pginit"

exit 0