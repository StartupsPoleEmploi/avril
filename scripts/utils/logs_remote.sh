#!/bin/bash

ssh deploy@avril "cd /home/docker/avril && docker-compose logs --tail=100 -f $*"