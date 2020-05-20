#!/bin/bash

docker-compose exec postgres bash -c 'psql -h $POSTGRES_HOST -d $POSTGRES_DB -U $POSTGRES_USER'