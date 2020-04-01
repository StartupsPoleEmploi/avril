defmodule VaeWeb.Resolvers.Application do
  import VaeWeb.Resolvers.ErrorHandler

  alias Vae.{Applications, Authorities}

  @application_not_found "La candidature est introuvable"
  @delegate_not_found "Le certificateur est introuvable"
  @attach_delegate_error "L'ajout du certificateur à votre candidature a échoué"

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

  defp format_application_error_message(application_id),
    do: "Application id #{application_id} not found"

  defp format_delegate_error_message(delegate_id), do: "Delegate id #{delegate_id} not found"
end
