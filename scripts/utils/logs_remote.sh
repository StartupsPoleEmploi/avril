#!/bin/bash

ssh deploy@avril_dev "cd /home/docker/avril && docker-compose logs --tail=100 -f $*"