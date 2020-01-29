#!/bin/bash

cd "$(dirname "$0")/.."

mix deps.get --only prod && \
mix do compile