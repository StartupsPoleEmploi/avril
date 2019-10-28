FROM elixir:1.8.0

RUN apt-get update
RUN apt-get install -y \
    inotify-tools libfontenc1 libxfont1 xfonts-encodings xfonts-utils xfonts-base xfonts-75dpi

# Install wkhtmltopdf
RUN wget -P /root https://downloads.wkhtmltopdf.org/0.12/0.12.5/wkhtmltox_0.12.5-1.stretch_amd64.deb
RUN dpkg -i /root/wkhtmltox_0.12.5-1.stretch_amd64.deb || true

# Install goon
RUN wget -P /root https://github.com/alco/goon/releases/download/v1.1.1/goon_linux_amd64.tar.gz
RUN tar -C /root -vxf /root/goon_linux_amd64.tar.gz
RUN mv /root/goon /usr/local/bin/

# Install node
RUN curl -sL https://deb.nodesource.com/setup_12.x | bash
RUN apt-get install -y nodejs

RUN mkdir -p /app

ADD assets/package.json /app/assets/package.json
# ADD assets/package-lock.json /app/assets/package-lock.json
# ADD mix.exs /app/mix.exs
# ADD mix.lock /app/mix.lock
#
# WORKDIR /app
#
# # Install dependencies
# RUN npm install --prefix ./assets
# RUN mix local.hex --force
# RUN mix local.rebar --force
# RUN mix deps.get # TODO: make it non interactive

# Setup DB
# RUN mix ecto.create && mix ecto.migrate # Note: run once the db is connected
# RUN mix run priv/repo/seeds.exs