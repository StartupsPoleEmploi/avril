defmodule Vae.Authorities.Rncp.Update do
  require Logger

  alias Vae.Certification
  alias Vae.Authorities.Rncp.Api

  def update_all(page \\ 1) do
    Logger.info("Starting update")
    Api.query_all(fn fiche ->
      %{rncp_id: rncp_id} = params = Vae.Authorities.Rncp.FicheHandler.api_fiche_to_certification_params(fiche)

      Certification.rncp_changeset(rncp_id, params)
      |> Certification.rncp_update()
    end, page)
    Logger.info("Update finished. Updating last import date")
    update_last_rncp_import_fake_certification()
    Logger.info("Transfering old applications")
    Certification.transfert_old_applications_to_newer_certification()
    Logger.info("All done!")
  end

  defp update_last_rncp_import_fake_certification() do
    Certification.fake_certification()
    |> Certification.rncp_changeset()
    |> Certification.rncp_update()
  end

end