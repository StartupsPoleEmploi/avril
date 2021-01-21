defmodule VaeWeb.Resolvers.Application do
  require Logger

  import VaeWeb.Resolvers.ErrorHandler
  import Ecto.Query
  import Geo.PostGIS

  alias Vae.{Applications, Delegate, Meeting, Repo, UserApplication}
  alias VaeWeb.ApplicationEmail

  @application_not_found "La candidature est introuvable"
  @no_delegate_found "Aucun certificateur n'a été trouvé"
  @delegate_not_found "Le certificateur est introuvable"
  @no_meeting_found "Nous n'avons pas pu récupérer les réunions d'information"
  @attach_delegate_error "L'ajout du certificateur à votre candidature a échoué"
  @register_meeting_error "La prise de rendez-vous a échoué"
  @submit_error "Une erreur est survenue lors de la transmission de la candidature"
  @upload_error "Une erreur est survenue lors de l'envoi de la pièce jointe"
  @delete_error "Une erreur est survenue lors de la suppression de la candidature"

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
        %{application_id: application_id, geo: %{lng: lng, lat: lat}, radius: radius, administrative: administrative},
        %{context: %{current_user: user}}
      ) do
    with(
      application when not is_nil(application) <-
           Applications.get_application_from_id_and_user_id(application_id, user.id),
      geom <- %Geo.Point{coordinates: {lng, lat}},
      delegates <- from(d in Delegate)
        |> join(:inner, [d], assoc(d, :certifications))
        |> where([d], d.is_active)
        |> Vae.Maybe.if(is_binary(administrative), &where(&1, [d], d.administrative == ^administrative))
        |> where([d, c], c.id == ^application.certification_id)
        |> Vae.Maybe.if(is_number(radius), &where(&1, [d], st_dwithin_in_meters(d.geom, ^geom, ^radius)))
        |> preload([d], [:certifiers])
        |> order_by([d], [asc: st_distance(d.geom, ^geom)])
        |> limit(12)
        |> Repo.all()
    ) do
      {:ok, delegates}
    else
      {:error, msg} ->
        error_response(@no_delegate_found, msg)
      _error ->
        error_response(@application_not_found, format_application_error_message(application_id))
    end
  end

  def meetings_search(
        _,
        %{delegate_id: delegate_id},
        %{context: %{current_user: _user}}
      ) do
    with(%Delegate{} = delegate <- Repo.get(Delegate, delegate_id)) do
      {:ok, Meeting.find_future_meetings_for_delegate(delegate) |> Enum.map(fn %Meeting{data: data} -> data end)}
    else
      {:error, msg} ->
        error_response(@no_meeting_found, msg)
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
           {:delegate, Repo.get(Delegate, delegate_id) |> Repo.preload(:certifiers)},
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
    with(
      application <- Applications.get_application_from_id_and_user_id(application_id, user.id),
      {:ok, registered_application} <- Applications.register_to_a_meeting(application, meeting_id)
    ) do
      VaeWeb.Emails.send_user_meeting_confirmation(registered_application)
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        error_response(@register_meeting_error, changeset)

      {:error, %Meeting{}} ->
        error_response(@register_meeting_error, "")

      _error ->
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

  def delete_application(_, %{id: application_id}, %{context: %{current_user: user}}) do
    with(
      {:application, %UserApplication{submitted_at: submitted_at} = application} <-
        {
          :application,
          Applications.get_application_from_id_and_user_id(application_id, user.id)
            |> Repo.preload([:user, :delegate, :certification])
        },
      {:ok, _deleted} <- UserApplication.delete_with_resumes(application)
    ) do
      if not is_nil(submitted_at) do
        {:ok, _} = ApplicationEmail.delegate_cancelled_application(application) |> VaeWeb.Mailer.send() |> IO.inspect()
      end
      {:ok, Applications.get_applications(user.id)}
    else
      {:application, _error} ->
        error_response(@application_not_found, format_application_error_message(application_id))

      {:error, %Ecto.Changeset{} = changeset} ->
        error_response(@delete_error, changeset)

      _err ->
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
        error_response(@upload_error, changeset)

      error ->
        Logger.error(fn -> inspect(error) end)
        error_response("Une erreur est survenue", "")
    end
  end

  def get_booklet(_, %{application_id: application_id}, %{context: %{current_user: user}}) do
    with {:application, application} when not is_nil(application) <-
           {:application,
            Applications.get_application_from_id_and_user_id(application_id, user.id)},
         {:ok, booklet} <- Applications.get_booklet(application) do
      {:ok, booklet}
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

  def set_booklet(_, %{input: %{application_id: application_id, booklet: booklet}}, %{
        context: %{current_user: user}
      }) do
    with {:application, application} <-
           {:application,
            Applications.get_application_from_id_and_user_id(application_id, user.id)},
         {:ok, updated_application} <- Applications.set_booklet(application, booklet) do
      {:ok, updated_application.booklet_1}
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
