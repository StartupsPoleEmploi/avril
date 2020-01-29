#!/bin/bash

until psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -c '\q' 2> /dev/null; do
  >&2 echo "[WAIT] Postgres is unavailable"
  sleep 1
done

echo "[DONE] Postgres is ready"

exit 0