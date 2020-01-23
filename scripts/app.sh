#!/bin/bash

cd "$(dirname "$0")/.."

# Compile elixir
# ./scripts/wait_for.sh compile && \

mix deps.get --only prod && \
mix do compile && \
./scripts/wait_for_pg.sh && \
mix ecto.migrate && \
mix phx.server