#! /bin/bash

FILENAME="${1:-latest}.dump"

echo "Stopping phoenix ..." && \
docker-compose stop phoenix && \
echo "Restoring $FILENAME ..." && \
docker-compose exec postgres bash -c 'pg_restore --verbose --clean --no-acl --no-owner -h $POSTGRES_HOST -d $POSTGRES_DB -U $POSTGRES_USER /pg-dump/latest.dump' && \
echo "Restored :) Restarting phoenix" && \
docker-compose start phoenix && \
echo "Restartid phoenix :)"
