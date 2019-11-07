#!/bin/bash

cd "$(dirname "$0")/.."

# Compile elixir
./scripts/wait_for.sh compile && \
mix phx.server