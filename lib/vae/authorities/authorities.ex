defmodule Vae.Authorities do
  alias Vae.Delegate
  alias Vae.Repo

  def get_first_certifier_from_delegate(%Delegate{} = delegate) do
    Ecto.assoc(delegate, :certifiers)
    |> Repo.all()
    |> hd()
  end

  def get_first_certifier_from_delegate(_), do: nil
end
