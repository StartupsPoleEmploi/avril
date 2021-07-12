defmodule VaeWeb.ViewHelpers do
  @moduledoc """
  Conveniences for some html tags and conditions
  """

  use Phoenix.HTML

  @doc """
  Generates a link tag with target: _blank option
  """
  def level_info_by_level(3), do: "CAP / BEP"
  def level_info_by_level(4), do: "Bac / BP / BT"
  def level_info_by_level(5), do: "Bac +2 / DUT / BTS"
  def level_info_by_level(6), do: "Bac +3 / Bac +4"
  def level_info_by_level(7), do: "Bac +5 et plus"
  def level_info_by_level(8), do: "Bac +8"
  def level_info_by_level(_), do: "Sans Diplôme"

  def resume_category_label("self_employed"), do: "Activité non salariée"
  def resume_category_label("employment_certification"), do: "Attestation employeur"
  def resume_category_label("volunteering"), do: "Bénévolat"
  def resume_category_label("job_certification"), do: "Contrat de travail"
  def resume_category_label("resume"), do: "CV"
  def resume_category_label("certification"), do: "Diplôme"
  def resume_category_label("payslip"), do: "Fiche de paie"
  def resume_category_label("id"), do: "Pièce d'identité"
  def resume_category_label("other"), do: "Autre document"
  def resume_category_label(_label), do: "Pièce jointe"

  def meta_certification(%{rome: r, delegate: d}) when not is_nil(r) and not is_nil(d) do
    " pour #{r.label} à #{d.name}"
  end

  def meta_certification(%{delegate: d}) when not is_nil(d) do
    " à #{d.name}"
  end

  def meta_certification(%{rome: r}) when not is_nil(r) do
    " pour #{r.label}"
  end

  def meta_certification(_), do: ""

  def meta_delegate(%{certification: c}) when not is_nil(c) do
    " pour #{Vae.Certification.name(c)}"
  end

  def meta_delegate(_), do: ""
end
