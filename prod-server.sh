#!/bin/bash

npm run deploy --prefix ./assets \
&& mix phx.digest \
&& mix ecto.migrate \
&& mix phx.server