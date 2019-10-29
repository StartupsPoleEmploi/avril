# Notes pour démarrer avec Phoenix lorsqu'on connait Ruby-on-Rails

## Fichiers

- App code : `/app` -> `/web`
- Migrations : `/db/migrate` -> `/priv/repo/migrations`
- Assets : `/app/assets` -> `/assets`
- Router : `/config/router.rb` -> `/web/router.ex`
- Vues : `/app/views` -> `/web/templates` (`/web/views` existe mais ressemble plus aux `helpers` de Rails)

## Commandes

- `rails new APP_NAME` -> `mix phx.new APP_NAME`
- `bundle install` -> `mix deps.get`
- `rake db:create` -> `mix ecto.create`
- `rails server` -> `mix phx.server`
- `rake routes` -> `mix phx.routes`
- `rake generate scaffold Post title:string body:text` -> `mix phx.gen.html Post posts title body:text`
- `rake generate migration AddFieldToModel` -> `mix ecto.gen.migration add_field_to_model`
- `rake db:migrate` -> `mix ecto.migrate`
- `rake db:rollback` -> `mix ecto.rollback`

## ORM

C'est [`Ecto`](https://hexdocs.pm/ecto/Ecto.html) qui remplace [`Active Record`](https://github.com/rails/rails/tree/master/activerecord).

Quelques équivalents :

- Trouver un enregistrement par id : `User.find(:id)` -> `Repo.get(User, :id)`
- Trouver un enregistrement par un autre champs : `User.find_by(email: 'me@example.com')` -> `Repo.get_by(User, email: "me@example.com")`
- Supprimer un enregistremnt : `user.destroy` -> `Repo.delete(user)`
- Trouver plusieurs enregistrements : `User.where('confirmed_at IS NOT NULL')` -> `Repo.all(from(u in User, where: not is_nil(u.confirmed_at)))`
- Charger une association : `User.includes(:billing_information).find(:id)` -> `Repo.get(User, :id) |> Repo.preload(:billing_information)`