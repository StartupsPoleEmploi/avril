FROM elixir:latest

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
RUN wget -P /root https://nodejs.org/dist/v10.15.3/node-v10.15.3-linux-x64.tar.xz
RUN tar -C /opt -vxf /root/node-v10.15.3-linux-x64.tar.xz
ENV NODEJS_HOME=/opt/node-v10.15.3-linux-x64/bin/
ENV PATH=$NODEJS_HOME:$PATH
ADD package.json /app/package.json
ADD package-lock.json /app/package-lock.json
RUN npm install

WORKDIR /app
ADD mix.exs /app/mix.exs

# Install Elixir dependencies
RUN mix local.hex --force
RUN mix deps.get # TODO: make it non interactive

# Setup DB
# RUN mix ecto.create && mix ecto.migrate # Note: run once the db is connected
# RUN mix run priv/repo/seeds.exs