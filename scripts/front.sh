#!/bin/bash

cd "$(dirname "$0")/.."


# Check if yarn available, otherwise use npm
if hash yarn 2>/dev/null; then
  yarn --cwd ./assets install && \
  yarn --cwd ./assets deploy && \
  yarn --cwd ./assets generate
else
  npm install --prefix ./assets && \
  npm run deploy --prefix ./assets && \
  npm run generate --prefix ./assets
fi

mix phx.digest