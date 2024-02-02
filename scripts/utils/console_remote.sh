#!/bin/bash

CONTAINER_ID=$(ssh deploy@avril_dev 'docker ps -a -q -f="name=avril_phoenix"')
ssh -tt deploy@avril "docker exec -it $CONTAINER_ID iex -S mix"