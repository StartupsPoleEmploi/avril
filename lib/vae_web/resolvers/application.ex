defmodule VaeWeb.Resolvers.Application do
  require Logger

  import VaeWeb.Resolvers.ErrorHandler

  alias Vae.{Applications, Authorities}

  @application_not_found "La candidature est introuvable"
  @delegate_not_found "Le certificateur est introuvable"
  @attach_delegate_error "L'ajout du certificateur à votre candidature a échoué"
  @register_meeting_error "La prise de rendez-vous a échoué"
  @submit_error "Une erreur est survenue lors de l'envoi de la candidature"

  def application_items(_, _args, %{context: %{current_user: user}}) do
    {:ok, Applications.get_applications(user.id)}
  end

  def application_items(_, _args, _), do: {:ok, []}

  def application(_, %{id: id}, %{context: %{current_user: user}}) do
    case Applications.get_application_from_id_and_user_id(id, user.id) do
      nil ->
        error_response(@application_not_found, format_application_error_message(id))

      application ->
        {:ok, application}
    end
  end

  def application(_, _args, _), do: {:ok, nil}

  def delegates_search(
        _,
        %{application_id: application_id, geo: geoloc, postal_code: postal_code},
        %{context: %{current_user: user}}
      ) do
    with application when not is_nil(application) <-
           Applications.get_application_from_id_and_user_id(application_id, user.id),
         delegates <-
           Authorities.search_delegates(application.certification, geoloc, postal_code) do
      {:ok, delegates}
    else
      _ ->
        error_response(@application_not_found, format_application_error_message(application_id))
    end
  end

  def attach_delegate(
        _,
        %{input: %{application_id: application_id, delegate_id: delegate_id}},
        %{context: %{current_user: user}}
      ) do
    with {_, application} when not is_nil(application) <-
           {:application,
            Applications.get_application_from_id_and_user_id(application_id, user.id)},
         {_, delegate} when not is_nil(delegate) <-
           {:delegate, Authorities.get_delegate(delegate_id)},
         {:ok, updated_application} <-
           Applications.attach_delegate(application, delegate) do
      {:ok, updated_application}
    else
      {:error, changeset} ->
        error_response(@attach_delegate_error, changeset)

      {:application, _error} ->
        error_response(@application_not_found, format_application_error_message(application_id))

      {:delegate, _error} ->
        error_response(@delegate_not_found, format_delegate_error_message(delegate_id))
    end
  end

  def register_meeting(_, %{input: %{meeting_id: ""}}, _),
    do: error_response(@register_meeting_error, "Meeting ID must be provided")

  def register_meeting(
        _,
        %{input: %{application_id: application_id, meeting_id: meeting_id}},
        %{context: %{current_user: user}}
      ) do
    with application <-
           Applications.get_application_from_id_and_user_id(application_id, user.id),
         {:ok, registered_application} <-
           Applications.register_to_a_meeting(application, meeting_id),
         {:ok, access_application} <-
           Applications.generate_delegate_access_hash(registered_application) do
      case VaeWeb.Emails.send_user_meeting_confirmation(access_application) do
        {:ok, _object} ->
          Applications.set_meeting_submitted_at(access_application)

        {:error, error} ->
          error_response(@register_meeting_error, error)

        error ->
          error_response(@register_meeting_error, error)
      end
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        error_response(@register_meeting_error, changeset)

      _ ->
        error_response(@application_not_found, format_application_error_message(application_id))
    end
  end

  def submit_application(_, %{id: application_id}, %{context: %{current_user: user}}) do
    with {:application, application} <-
           {:application,
            Applications.get_application_from_id_and_user_id(application_id, user.id)},
         {:ok, application} <- Applications.prepare_submit(application) do
      case VaeWeb.Emails.send_submission_confirmations(application) do
        {:ok, application} ->
          Applications.set_submitted_now(application)

        {:error, msg} ->
          Logger.error(fn -> "Error, while sending application #{inspect(msg)}" end)
          error_response("Une erreur est survenue", inspect(msg))
      end
    else
      {:application, _error} ->
        error_response(@application_not_found, format_application_error_message(application_id))

      {:error, %Ecto.Changeset{} = changeset} ->
        error_response(@submit_error, changeset)

      _ ->
        error_response("Une erreur est survenue", "")
    end
  end

  def upload_resume(%{id: application_id, resume: resume}, %{context: %{current_user: user}}) do
    with {:application, application} <-
           {:application,
            Applications.get_application_from_id_and_user_id(application_id, user.id)},
         {:ok, application} <- Applications.attach_resume_to_application(application, resume) do
      {:ok, application}
    else
      {:application, _error} ->
        error_response(@application_not_found, format_application_error_message(application_id))

      {:error, %Ecto.Changeset{} = changeset} ->
        error_response(@submit_error, changeset)

      error ->
        Logger.error(fn -> inspect(error) end)
        error_response("Une erreur est survenue", "")
    end
  end

  defp format_application_error_message(application_id),
    do: "Application id #{application_id} not found"

  defp format_delegate_error_message(delegate_id), do: "Delegate id #{delegate_id} not found"
end
