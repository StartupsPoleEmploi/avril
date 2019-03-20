# Notes on working with Phoenix when coming from Rails

## Files structure

- App code : `/app` -> `/web`
- Migrations : `/db/migrate` -> `/priv/repo/migrations`
- Assets : `/app/assets` -> `/priv/static`
- Router : `/config/router.rb` -> `/web/router.ex`

## Commands

- `rails new APP_NAME` -> `mix phx.new APP_NAME`
- `bundle install` -> `mix deps.get`
- `rake db:create` -> `mix ecto.create`
- `rails server` -> `mix phx.server`
- `rake routes` -> `mix phoenix.routes`
- `rake generate scaffold Post title:string body:text` -> `mix phoenix.gen.html Post posts title body:text`

## Active Record

- `User.find(:id)` -> `Repo.get(User, :id)`
