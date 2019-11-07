#!/bin/bash

# Compile elixir
mix deps.get --only prod && \
mix do compile && \
./wait_for_pginit.sh && \
mix phx.server