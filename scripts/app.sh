#!/bin/bash

cd "$(dirname "$0")/.."

# Compile elixir
mix deps.get --only prod && \
mix do compile && \
./scripts/wait_for_pginit.sh && \
# mix ecto.migrate && \
mix phx.server