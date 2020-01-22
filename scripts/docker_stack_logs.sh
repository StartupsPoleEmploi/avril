#!/bin/bash

SERVICES=$(docker stack services avril --format "{{.Name}}")

COMMAND="{ "
JOINER=""

for SERVICE in $SERVICES
do
  COMMAND="$COMMAND $JOINER docker service logs $SERVICE"
  JOINER="&"
done

COMMAND="$COMMAND; }"

eval $COMMAND