defmodule Vae.CertificationView do
  use Vae.Web, :view
  use Scrivener.HTML

  alias Vae.Repo.NewRelic, as: Repo
  alias Vae.Delegate
  alias Vae.Certification

  def certifiers(certification) do
    certification
    |> Repo.all()
  end

  def formatted_name(certification) do
    "#{certification.acronym} #{String.downcase(certification.label)}"
  end
end
