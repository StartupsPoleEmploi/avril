defmodule VaeWeb.Resolvers.Authorities do
  alias Vae.Authorities
  alias Vae.Delegate

  def certifier_item(%Delegate{} = delegate, _args, _) do
    {:ok, Authorities.get_first_certifier_from_delegate(delegate)}
  end

  def certifier_item(_, _args, _), do: {:ok, nil}
end
