defmodule Vae.Authorities.Rncp.Update do
  require Logger

  alias Vae.{Certification, Repo}
  alias Vae.Authorities.Rncp.{Api, CustomRules}

  def update_all(page \\ 1) do
    try do
      Logger.info("Starting update")
      Api.query_all(fn fiche ->
        %{rncp_id: rncp_id} = params = Vae.Authorities.Rncp.FicheHandler.api_fiche_to_certification_params(fiche)

        if CustomRules.accepted_fiche?(fiche) do
          Certification.rncp_changeset(rncp_id, params)
          |> Certification.rncp_update()
        else if certification = Repo.get_by(Certification, rncp_id: rncp_id) |> Repo.preload(:applications) do
          try do
            Logger.info("Certification should be RNCP#{rncp_id} deleted?")
            Repo.delete(certification)
          rescue
            error ->
              Logger.error(inspect(error))
              Logger.warn("Certification RNCP#{rncp_id} should not be imported in Avril and has applications. Simply deactivating")
              Certification.rncp_changeset(rncp_id, params)
              |> Certification.rncp_update()
          end
        end
        end
      end, page)
      Logger.info("Update finished at page #{page}. Updating last import date")
      update_last_rncp_import_fake_certification()
    after
      Logger.info("== Cleaning it up! ==")
      Logger.info("Updating materialized views")
      Certification.refresh_materialized_view()
      Logger.info("Transfering old applications")
      Certification.transfert_old_applications_to_newer_certification()
      Logger.info("All done!")
    end
  end

  defp update_last_rncp_import_fake_certification() do
    Certification.fake_certification()
    |> Certification.rncp_changeset()
    |> Certification.rncp_update()
  end

end