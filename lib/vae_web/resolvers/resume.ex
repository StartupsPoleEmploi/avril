defmodule VaeWeb.Resolvers.Resume do
  require Logger

  import VaeWeb.Resolvers.ErrorHandler

  alias Vae.{Applications, Resume, Repo}

  @resume_not_found "La pièce jointe est introuvable"
  @edit_resume_error "La modification de la pièce jointe a échoué"
  @delete_resume_error "La suppression de la pièce jointe a échoué"

  def edit_resume(_, %{id: resume_id, params: params}, %{context: %{current_user: user}}) do
    with(
      {_, resume} when not is_nil(resume) <-
           {:resume, Applications.get_resume_from_id_and_user_id(resume_id, user.id)},
      {:ok, edited_resume} <- Resume.changeset(resume, params) |> Repo.update()
    ) do
      {:ok, edited_resume}
    else
      {:resume, _} ->
        error_response(@resume_not_found, "Resume id #{resume_id} not found")

      {:error, changeset} ->
        error_response(@edit_resume_error, changeset)
    end
  end

  def delete_resume(_, %{id: resume_id}, %{context: %{current_user: user}}) do
    with {_, resume} when not is_nil(resume) <-
           {:resume, Applications.get_resume_from_id_and_user_id(resume_id, user.id)},
         {:ok, deleted} <- Applications.delete_resume(resume) do
      {:ok, deleted}
    else
      {:resume, _} ->
        error_response(@resume_not_found, "Resume id #{resume_id} not found")

      {:error, changeset} ->
        error_response(@delete_resume_error, changeset)
    end
  end
end
