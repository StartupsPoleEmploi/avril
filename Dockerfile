# FROM bitwalker/alpine-elixir-phoenix:latest AS phx-builder
#
# # alpine-wkhtmltopdf
# RUN apk add --update --no-cache \
#     libgcc libstdc++ libx11 glib libxrender libxext libintl \
#     libcrypto1.0 libssl1.0 \
#     ttf-dejavu ttf-droid ttf-freefont ttf-liberation ttf-ubuntu-font-family
# COPY wkhtmltopdf /usr/bin
#
# ENV MIX_ENV=prod DEPLOY_SERVER=flynn
#
# ADD mix.exs mix.lock ./
# RUN mix do deps.get, deps.compile
#
# ADD package.json ./
# RUN npm install
#
# ADD . .
#
# RUN npm run deploy
# RUN mix do compile, phx.digest
#
# FROM bitwalker/alpine-elixir:latest
#
# EXPOSE 80
# ENV PORT=80 MIX_ENV=prod DEPLOY_SERVER=flynn
#
# COPY --from=phx-builder /opt/app/_build /opt/app/_build
# COPY --from=phx-builder /opt/app/priv /opt/app/priv
# COPY --from=phx-builder /opt/app/config /opt/app/config
# COPY --from=phx-builder /opt/app/lib /opt/app/lib
# COPY --from=phx-builder /opt/app/deps /opt/app/deps
# COPY --from=phx-builder /opt/app/.mix /opt/app/.mix
# COPY --from=phx-builder /opt/app/mix.* /opt/app/
#
# # USER default
#
# CMD ["mix", "do", "ecto.migrate", ",", "phx.server"]

FROM bitwalker/alpine-elixir-phoenix:latest

USER root

# alpine-wkhtmltopdf
RUN apk add --update --no-cache \
    libgcc libstdc++ libx11 glib libxrender libxext libintl \
    libcrypto1.0 libssl1.0 \
    ttf-dejavu ttf-droid ttf-freefont ttf-liberation ttf-ubuntu-font-family
COPY wkhtmltopdf /usr/bin

# Set exposed ports
EXPOSE 80
ENV PORT=80 MIX_ENV=prod DEPLOY_SERVER=flynn

# Cache elixir deps
ADD mix.exs mix.lock ./
RUN mix do deps.get, deps.compile

# Same with npm deps
ADD package.json ./
RUN npm install

ADD . .

# Run frontend build, compile, and digest assets
RUN npm run deploy && \
    mix do compile, phx.digest

# USER default

CMD ["mix", "do", "ecto.migrate", ",", "phx.server"]
