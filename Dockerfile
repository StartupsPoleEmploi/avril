FROM bitwalker/alpine-elixir-phoenix:latest

USER root

# alpine-wkhtmltopdf
RUN apk add --update --no-cache \
    libgcc libstdc++ libx11 glib libxrender libxext libintl \
    libcrypto1.0 libssl1.0 \
    ttf-dejavu ttf-droid ttf-freefont ttf-liberation ttf-ubuntu-font-family
COPY bin/wkhtmltopdf /bin

# Set exposed ports
EXPOSE 80
ENV PORT=80 MIX_ENV=prod DEPLOY_SERVER=docker

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
