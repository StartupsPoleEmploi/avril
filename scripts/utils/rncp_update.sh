#!/bin/bash

FILENAME=${1?"FILENAME required"}

cd "$(dirname "$0")/../.."

./scripts/wait-for-postgres.sh && \
mix ecto.migrate && \
POSTGRES_TIMEOUT=500000 \
mix RncpUpdate -f $FILENAME