#!/bin/bash

cd "$(dirname "$0")/.."

yarn --cwd ./assets install && \
yarn --cwd ./assets deploy && \
yarn --cwd ./assets generate && \
mix phx.digest