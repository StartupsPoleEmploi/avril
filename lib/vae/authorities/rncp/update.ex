defmodule Vae.Authorities.Rncp.Update do
  require Logger

  alias Vae.Certification
  alias Vae.Authorities.Rncp.Api

  def update_all() do
    Logger.info("Starting update")
    Api.query_all(fn fiche ->
      %{rncp_id: rncp_id} = params = Vae.Authorities.Rncp.FicheHandler.api_fiche_to_certification_params(fiche)

      Certification.rncp_changeset(rncp_id, params)
      |> Certification.rncp_update()
    end)
    Logger.info("Update finished. Transfering old applications")
    Certification.transfert_old_applications_to_newer_certification()
  end

end