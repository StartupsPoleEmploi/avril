defmodule VaeWeb.Resolvers.Resume do
  require Logger

  import VaeWeb.Resolvers.ErrorHandler

  alias Vae.Applications

  @resume_not_found "Le CV est introuvable"
  @delete_resume_error "La suppression du CV a échoué"

  def delete_resume(_, %{id: resume_id}, %{context: %{current_user: user}}) do
    with {_, resume} when not is_nil(resume) <-
           {:resume, Applications.get_resume_from_id_and_user_id(resume_id, user.id)},
         {:ok, _deleted} <- Applications.delete_resume(resume) do
      {:ok, "success"}
    else
      {:resume, _} ->
        error_response(@resume_not_found, "Resume id #{resume_id} not found")

      {:error, changeset} ->
        error_response(@delete_resume_error, changeset)
    end
  end
end
