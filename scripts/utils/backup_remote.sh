#! /bin/bash

FILENAME="${1:-latest}.dump"

echo "Building $FILENAME ..." && \
ssh -tt deploy@avril "cd /home/docker/avril && docker-compose exec postgres bash -c 'pg_dump -h \$POSTGRES_HOST -d \$POSTGRES_DB -U \$POSTGRES_USER -F c -f /pg-dump/$FILENAME'" && \
echo "Backed up :)" && \
scp deploy@avril:/home/docker/avril/db/dumps/$FILENAME db/dumps
