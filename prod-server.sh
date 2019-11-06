#!/bin/bash

# Compile elixir
mix deps.get --only prod && \
mix do compile && \
# Build assets
npm run deploy --prefix ./assets && \
mix phx.digest && \
./db/wait_for_init.sh && \
mix ecto.migrate && \
mix phx.server