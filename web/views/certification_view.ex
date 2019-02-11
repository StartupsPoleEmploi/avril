defmodule Vae.CertificationView do
  use Vae.Web, :view
  use Scrivener.HTML

  alias Vae.Repo.NewRelic, as: Repo
  alias Vae.Delegate
  alias Vae.Certification

  def to_process(conn, certification, nil) do
    process_path(
      conn,
      :index,
      certification: certification
    )
  end

  def to_process(conn, certification, search) do
    params =
      Enum.filter(search, fn {_k, v} -> v != "" end)
      |> Keyword.take(["lat", "lng"])
      |> Keyword.put(:certification, certification)
      |> Keyword.put(:"search[profession]", search["profession"])

    process_path(
      conn,
      :index,
      params
    )
  end

  def certifiers(certification) do
    certification
    |> Repo.all()
  end
end
