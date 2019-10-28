#!/bin/bash

mix deps.get --only prod && \
# mix deps.compile && \
# npm install --prefix ./assets && \
npm run deploy --prefix ./assets && \
mix phx.digest && \
mix do compile && \
mix ecto.migrate && \
mix phx.server