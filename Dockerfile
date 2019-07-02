FROM elixir:1.8.0

RUN apt-get update
RUN apt-get install -y inotify-tools

# Install wkhtmltopdf
RUN wget -P /root https://downloads.wkhtmltopdf.org/0.12/0.12.5/wkhtmltox_0.12.5-1.stretch_amd64.deb
RUN dpkg -i /root/wkhtmltox_0.12.5-1.stretch_amd64.deb || true
RUN apt-get install -f -y
RUN dpkg -i /root/wkhtmltox_0.12.5-1.stretch_amd64.deb

# Install goon
RUN wget -P /root https://github.com/alco/goon/releases/download/v1.1.1/goon_linux_amd64.tar.gz
RUN tar -C /root -vxf /root/goon_linux_amd64.tar.gz
RUN mv /root/goon /usr/local/bin/

# Install node TODO: consider moving to other container
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash
RUN apt-get install -y nodejs
RUN npm install -g npm

ADD assets/package.json /app/assets/package.json
ADD assets/package-lock.json /app/assets/package-lock.json
ADD mix.exs /app/mix.exs

WORKDIR /app

# Install dependencies
RUN cd assets npm install
RUN mix local.hex --force
RUN mix deps.get # TODO: make it non interactive

# Setup DB
# RUN mix ecto.create && mix ecto.migrate # Note: run once the db is connected
# RUN mix run priv/repo/seeds.exs