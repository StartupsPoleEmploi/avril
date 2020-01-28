#!/bin/bash

cd "$(dirname "$0")/.."

SERVICE_NAME=${1?"Usage: docker_update <SERVICE_NAME>"}

OLD_CONTAINER_ID=$(docker ps --format "table {{.ID}}  {{.Names}}  {{.CreatedAt}}" | grep $SERVICE_NAME | tail -n 1 | awk -F  "  " '{print $1}')
OLD_CONTAINER_NAME=$(docker ps --format "table {{.ID}}  {{.Names}}  {{.CreatedAt}}" | grep $SERVICE_NAME | tail -n 1 | awk -F  "  " '{print $2}')

docker-compose up -d --no-deps --scale $SERVICE_NAME=2 --no-recreate $SERVICE_NAME

NEW_CONTAINER_ID=$(docker ps --filter="since=$OLD_CONTAINER_NAME" --format "table {{.ID}}  {{.Names}}  {{.CreatedAt}}" | grep $SERVICE_NAME | tail -n 1 | awk -F  "  " '{print $1}')
NEW_CONTAINER_NAME=$(docker ps --filter="since=$OLD_CONTAINER_NAME" --format "table {{.ID}}  {{.Names}}  {{.CreatedAt}}" | grep $SERVICE_NAME | tail -n 1 | awk -F  "  " '{print $2}')

echo $OLD_CONTAINER_NAME
echo $NEW_CONTAINER_NAME

# wait for new container
docker kill -s SIGTERM $OLD_CONTAINER_ID
docker-compose restart nginx
sleep 1
docker rm -f $OLD_CONTAINER_ID
docker-compose up -d --no-deps --scale $SERVICE_NAME=1 --no-recreate $SERVICE_NAME
