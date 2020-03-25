defmodule VaeWeb.Resolvers.Application do
  alias Vae.Applications

  def application_items(_, _args, %{context: %{current_user: user}}) do
    {:ok, Applications.get_applications(user.id)}
  end

  def application_items(_, _args, _), do: {:ok, []}

  def application(_, %{id: id}, %{context: %{current_user: user}}) do
    {:ok, Applications.get_application_from_id_and_user_id(id, user.id)}
  end

  def application(_, _args, _), do: {:ok, nil}

  def get_delegates(_, %{application_id: application_id}, %{context: %{current_user: user}}) do
    %{"_geoloc" => geoloc, "postcode" => [postal_code]} =
      Vae.Places.get_geoloc_from_postal_code(user.postal_code)

    application = Applications.get_application_from_id_and_user_id(application_id, user.id)

    delegates =
      Vae.SearchDelegate.get_delegates(application.certification, geoloc, postal_code)
      |> case do
        {_meta, []} ->
          []

        {_meta, delegates} ->
          delegates
          |> Enum.map(fn delegate ->
            Vae.Repo.get(Vae.Delegate, delegate.id) |> Vae.Repo.preload(:certifiers)
          end)
      end

    {:ok, delegates}
  end
end
