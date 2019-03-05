defmodule Vae.DelegateView do
  use Vae.Web, :view
  use Scrivener.HTML

  def to_certification(conn, delegate, nil) do
    certification_path(conn, :index, certificateur: delegate)
  end

  def to_certification(conn, delegate, certification) do
    certification_path(conn, :show, certification, certificateur: delegate)
  end

  def to_certification_label(nil), do: "Les diplômes"
  def to_certification_label(_), do: "Les étapes VAE"
end
