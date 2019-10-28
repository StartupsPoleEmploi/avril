#!/bin/bash

# mix deps.get --only prod && \
# mix deps.compile && \
# npm install --prefix ./assets && \
npm run deploy --prefix ./assets && \
mix do compile, phx.digest && \
# (cd deps/bcrypt_elixir && make clean && make) && \
mix ecto.migrate && \
mix phx.server