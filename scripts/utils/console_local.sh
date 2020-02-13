#!/bin/bash

CONTAINER_ID=$(docker ps -a -q -f="name=avril_phoenix")
docker exec -it $CONTAINER_ID iex -S mix
