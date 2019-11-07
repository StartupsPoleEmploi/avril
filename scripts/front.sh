#!/bin/bash

cd "$(dirname "$0")/.."

npm install --prefix ./assets && \
npm run deploy --prefix ./assets && \
mix phx.digest