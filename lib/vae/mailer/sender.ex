defmodule Vae.Mailer.Sender do
  alias Vae.Mailer.Email

  def send(%Email{} = email) do
    utm_source = build_utm_source(email)

    build_message(email, utm_source)
    |> do_send()
    |> case do
      {:ok, %{"Messages" => messages}} ->
        Enum.map(messages, fn message ->
          %{email | email_state: String.to_atom(message["Status"])}
        end)

      {:error, %{"Messages" => errors}} ->
        Enum.map(errors, fn error ->
          %{email | email_state: String.to_atom(error["Status"]), errors: error["Errors"]}
        end)
    end
  end

  defp build_utm_source(email) do
    email.job_seeker.geolocation["administrative"] |> List.first()
  end

  defp build_message(
         %Email{custom_id: custom_id, job_seeker: job_seeker},
         utm_campaign \\ "lancement",
         utm_source
       ) do
    with {:email, email} when not is_nil(email) <-
           {:email, get_in(job_seeker, [Access.key(:email)])},
         first_name <- get_in(job_seeker, [Access.key(:first_name)]),
         last_name <- get_in(job_seeker, [Access.key(:last_name)]) do
      %{
        TemplateID: 475_460,
        TemplateLanguage: true,
        From: %{Email: "contact@avril.pole-emploi.fr", Name: "📜 Avril"},
        Variables: %{utm_campaign: utm_campaign, utm_source: utm_source},
        To: [%{Email: email, Name: "#{first_name} #{last_name}"}],
        CustomID: custom_id
      }
    else
      {:email, nil} -> nil
    end
  end

  defp do_send(message) do
    Mailjex.Delivery.send(%{
      Messages: [message]
    })
  end
end
