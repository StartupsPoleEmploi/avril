defmodule VaeWeb.Emails do
  require Logger

  alias Vae.Delegate
  alias VaeWeb.{ApplicationEmail, Mailer}

  def send_submission_confirmations(application) do
    if Delegate.is_asp?(application.delegate) do
      send_asp_application_submission_confirmation(application)
    else
      send_user_and_delegate_meeting_confirmation(application)
    end
  end

  def send_user_meeting_confirmation(application) do
    application
    |> ApplicationEmail.user_submission_confirmation()
    |> Mailer.send()
  end

  defp send_user_and_delegate_meeting_confirmation(application) do
    with {:user, {:ok, _sent}} <-
           send_user_meeting_confirmation(application),
         {:delegate, {:ok, _sent}} <-
           send_delegate_application_submission_and_meeting_confirmation(application) do
      {:ok, application}
    else
      {:error, {error, message}} ->
        Logger.error(fn -> inspect(error, limit: :infinity) end)
        {:error, message}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp send_asp_application_submission_confirmation(application) do
    application
    |> ApplicationEmail.asp_user_submission_confirmation()
    |> Mailer.send()
  end

  defp send_delegate_application_submission_and_meeting_confirmation(application) do
    application
    |> ApplicationEmail.delegate_submission()
    |> Mailer.send()
  end
end
