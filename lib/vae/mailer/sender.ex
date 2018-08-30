defmodule Vae.Mailer.Sender do
  alias Vae.Mailer.Email

  def send(%Email{} = email) do
    build_message(email)
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

  defp build_utm_source(job_seeker) do
    job_seeker.geolocation["administrative"] |> List.first()
  end

  defp build_message(
         %Email{custom_id: custom_id, job_seeker: job_seeker},
         utm_campaign \\ "lancement"
       ) do
    with email when not is_nil(email) <- get_email(job_seeker),
         first_name <- get_first_name(job_seeker),
         last_name <- get_last_name(job_seeker),
         utm_source <- build_utm_source(job_seeker) do
      mailjet_conf = Application.get_env(:vae, :mailjet)

      %{
        TemplateID: mailjet_conf.campaign_template_id,
        TemplateLanguage: true,
        From: %{
          Email: mailjet_conf.from_email,
          Name: "📜 Avril"
        },
        Variables: %{utm_campaign: utm_campaign, utm_source: utm_source},
        To:
          Map.get(mailjet_conf, :override_to, [
            %{Email: email, Name: "#{first_name} #{last_name}"}
          ]),
        CustomID: custom_id
      }
    else
      _ -> nil
    end
  end

  defp do_send(message) do
    Mailjex.Delivery.send(%{
      Messages: [message]
    })
  end

  defp get_email(job_seeker), do: get_in(job_seeker, [Access.key(:email)])
  defp get_first_name(job_seeker), do: get_in(job_seeker, [Access.key(:first_name)])
  defp get_last_name(job_seeker), do: get_in(job_seeker, [Access.key(:last_name)])
end
