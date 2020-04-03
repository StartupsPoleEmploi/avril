defmodule Vae.Authorities do
  import Ecto.Query

  alias Vae.Delegate
  alias Vae.{SearchDelegate, Repo}

  def get_first_certifier_from_delegate(%Delegate{} = delegate) do
    Ecto.assoc(delegate, :certifiers)
    |> Repo.all()
    |> hd()
  end

  def get_first_certifier_from_delegate(_), do: nil

  def search_delegates(certification, %{lat: lat, lng: lng}, postal_code) do
    SearchDelegate.get_delegates(
      certification,
      %{"lat" => lat, "lng" => lng},
      postal_code
    )
    |> Enum.map(& &1[:id])
    |> get_delegates_from_ids()
  end

  def get_delegates_from_ids(ids) do
    from(d in Delegate,
      where: d.id in ^ids
    )
    |> Repo.all()
  end

  def get_delegate(id) do
    Repo.get(Delegate, id)
    |> Repo.preload(:certifiers)
  end
end
