#!/bin/bash

npm run deploy --prefix ./assets \
&& mix phx.digest \
&& mix phx.server