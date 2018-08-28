defmodule Vae.CertificationView do
  use Vae.Web, :view
  use Scrivener.HTML

  alias Vae.Repo.NewRelic, as: Repo
  alias Vae.Delegate
  alias Vae.Certification

  def to_process(conn, certification, search) do
    params =
      Enum.filter(search, fn {k, v} -> v != "" end)
      |> Keyword.take(["lat", "lng"])
      |> Keyword.put(:certification, certification)
      |> Keyword.put(:"search[profession]", search["profession"])

    process_path(
      conn,
      :search,
      params
    )
  end

  def certifiers(certification) do
    certification
    |> Repo.all()
  end

  def formatted_name(certification) do
    "#{certification.acronym} #{String.downcase(certification.label)}"
  end

  def render("_certification_title", %{count: count} = assigns) when count == 0 do
    render("certification_title_no_result.html", assigns)
  end

  def render("_certification_title", assigns) do
    render("certification_title.html", assigns)
  end
end
