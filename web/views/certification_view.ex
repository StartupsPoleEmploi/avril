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

  def render("_certification_title.html", %{count: count} = assigns) when count == 0 do
    render("certification_title_no_result.html", assigns)
  end

  def render("_certification_title", assigns) do
    render("certification_title.html", assigns)
  end
end
