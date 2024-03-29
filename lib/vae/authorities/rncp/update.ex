defmodule Vae.Authorities.Rncp.Update do
  require Logger

  alias Vae.{Certification, Repo}
  alias Vae.Authorities.Rncp.{Api, CustomRules}

  def update_certification(rncp_id) do
    rncp_id
    |> Api.get()
    |> update_fiche()
  end

  def insert_all(page \\ 1) do
    try do
      Logger.info("Starting insert")
      Api.query_all(&insert_fiche(&1), page)
      Logger.info("Insert finished at page #{page}.")
    after
      Logger.info("== Cleaning it up! ==")
      Logger.info("Updating materialized views")
      Certification.refresh_materialized_view()
      Logger.info("Transfering old applications")
      Certification.transfert_old_applications_to_newer_certification()
      Logger.info("All done!")
    end
  end

  def update_all(page \\ 1) do
    try do
      Logger.info("Starting update")
      Api.query_all(&update_fiche(&1), page)
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

  def list_non_eligible(page \\ 1) do
    Logger.info("Starting to fetch API")
    Logger.info("RNCP_ID,ACRONYM,LABEL,ACTIVE")
    Api.query_all(&log_if_not_eligible_fiche(&1), page)
    Logger.info("Finished to fetch API")
  end

  defp update_last_rncp_import_fake_certification() do
    Certification.fake_certification()
    |> Certification.rncp_changeset()
    |> Certification.rncp_update()
  end

  defp log_if_not_eligible_fiche(fiche) do
    %{rncp_id: rncp_id, label: label, acronym: acronym, is_rncp_active: is_rncp_active} = params = Vae.Authorities.Rncp.FicheHandler.api_fiche_to_certification_params(fiche)

    accessible_vae = get_in(fiche, ["SI_JURY_VAE", "ACTIF"]) == "Oui"
    if !accessible_vae do
      Logger.info("#{rncp_id},#{acronym},#{label},#{is_rncp_active}")
    end
  end

  defp insert_fiche(fiche) do
    %{rncp_id: rncp_id} = params = Vae.Authorities.Rncp.FicheHandler.api_fiche_to_certification_params(fiche)

    if !Repo.get_by(Certification, rncp_id: rncp_id) do
      rncp_id
      |> Certification.rncp_changeset(params)
      |> Certification.rncp_update()
      case params[:older_certification] do
        %Certification{rncp_id: rncp_id} -> update_certification(rncp_id)
      _ -> nil
      end
    end
  end

  defp update_fiche(fiche) do
    %{rncp_id: rncp_id} = params = Vae.Authorities.Rncp.FicheHandler.api_fiche_to_certification_params(fiche)

    if CustomRules.accepted_fiche?(fiche) do
      rncp_id
      |> Certification.rncp_changeset(params)
      |> Certification.rncp_update()
    else
      if certification = Repo.get_by(Certification, rncp_id: rncp_id) |> Repo.preload(:applications) do
        try do
          Logger.info("Certification RNCP#{rncp_id} should be deleted?")
          Repo.delete(certification)
        rescue
          error ->
            Logger.error(inspect(error))
            Logger.warn("Certification RNCP#{rncp_id} should not be imported in Avril and has applications. Simply deactivating")
            Certification.rncp_changeset(rncp_id, params)
            |> Certification.rncp_update()
        end
      else
        Logger.info("Certification RNCP#{rncp_id} is not accepted")
      end
    end
  end

end