#!/bin/bash


cd "$(dirname "$0")/.."

SERVICE_NAME=${1?"Usage: docker_update <SERVICE_NAME>"}

echo "[INIT] Updating docker service $SERVICE_NAME"

OLD_CONTAINER_ID=$(docker ps --format "table {{.ID}}  {{.Names}}  {{.CreatedAt}}" | grep $SERVICE_NAME | tail -n 1 | awk -F  "  " '{print $1}')
OLD_CONTAINER_NAME=$(docker ps --format "table {{.ID}}  {{.Names}}  {{.CreatedAt}}" | grep $SERVICE_NAME | tail -n 1 | awk -F  "  " '{print $2}')

echo "[INIT] Scaling $SERVICE_NAME up"
docker-compose up -d --no-deps --scale $SERVICE_NAME=2 --no-recreate $SERVICE_NAME

NEW_CONTAINER_ID=$(docker ps --filter="since=$OLD_CONTAINER_NAME" --format "table {{.ID}}  {{.Names}}  {{.CreatedAt}}" | grep $SERVICE_NAME | tail -n 1 | awk -F  "  " '{print $1}')
NEW_CONTAINER_NAME=$(docker ps --filter="since=$OLD_CONTAINER_NAME" --format "table {{.ID}}  {{.Names}}  {{.CreatedAt}}" | grep $SERVICE_NAME | tail -n 1 | awk -F  "  " '{print $2}')

echo "[INIT] Starting $NEW_CONTAINER_NAME:"
docker logs --tail=10 -f $NEW_CONTAINER_ID &
LOGS_PID=$!

until [[ $(docker ps -a -f "id=$NEW_CONTAINER_ID" -f "health=healthy" -q) ]]; do
  # echo -ne "\r[WAIT] New instance $NEW_CONTAINER_NAME is not healthy yet ...";
  sleep 1
done
echo ""
kill $LOGS_PID
wait $LOGS_PID 2>/dev/null

echo "[DONE] $NEW_CONTAINER_NAME is healthy!"

echo "[DONE] Restarting nginx..."
docker-compose restart nginx

echo -n "[INIT] Stoping $OLD_CONTAINER_NAME: "
docker stop $OLD_CONTAINER_ID
until [[ $(docker ps -a -f "id=$OLD_CONTAINER_ID" -f "status=exited" -q) ]]; do
  echo -ne "\r[WAIT] $OLD_CONTAINER_NAME is getting killed ..."
  sleep 1
done
echo ""
echo "[DONE] $OLD_CONTAINER_NAME was killed."

echo -n "[DONE] Removing $OLD_CONTAINER_NAME: "
docker rm -f $OLD_CONTAINER_ID
echo "[DONE] Scaling down"
docker-compose up -d --no-deps --scale $SERVICE_NAME=1 --no-recreate $SERVICE_NAME
