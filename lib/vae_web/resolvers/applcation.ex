defmodule VaeWeb.Resolvers.Application do
  alias Vae.Applications
  alias Vae.User

  def application_items(_, _args, %{context: %{current_user: user}}) do
    {:ok, Applications.get_applications(user.id)}
  end

  def application_items(_, _args, _), do: {:ok, []}
end
