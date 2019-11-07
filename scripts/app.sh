#!/bin/bash

# Compile elixir
mix deps.get --only prod && \
mix do compile && \
./scripts/wait_for_pginit.sh && \
mix phx.server