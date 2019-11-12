#!/bin/bash

LOCK_FILE="db/pginit.lock"

cd "$(dirname "$0")/.."

touch $LOCK_FILE

mix deps.get --only prod && \
mix do compile && \
./scripts/wait_for.sh pginit && \
mix ecto.migrate

rm $LOCK_FILE

exit 0