#!/bin/bash

cd "$(dirname "$0")/.."

{
  ./scripts/init-phoenix-frontend.sh &
  ./scripts/init-phoenix-backend.sh &
  ./scripts/wait-for-postgres.sh &
}

wait

mix ecto.migrate && \
mix phx.server
