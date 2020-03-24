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
end
