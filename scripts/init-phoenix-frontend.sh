#!/bin/bash

cd "$(dirname "$0")/.."

yarn --cwd ./assets install && \
yarn --cwd ./assets deploy && \
mix phx.digest