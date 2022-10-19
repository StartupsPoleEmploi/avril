#!/bin/bash

ssh -tt deploy@avril "cd /home/docker/avril && docker-compose ps"