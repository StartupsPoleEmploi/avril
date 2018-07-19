defmodule Vae.Mailer.Sender do
  alias Vae.JobSeeker
  alias Vae.Mailer.Email

  def send(
        %Email{
          custom_id: custom_id,
          job_seeker: %JobSeeker{email: email, first_name: first_name, last_name: last_name}
        },
        utm_campaign \\ "lancement",
        utm_source
      ) do
    Mailjex.Delivery.send(%{
      "MJ-TemplateID": "475460",
      "MJ-TemplateLanguage": true,
      FromEmail: "contact@avril.pole-emploi.fr",
      FromName: "📜 Avril",
      Vars: %{utm_campaign: utm_campaign, utm_source: utm_source},
      Recipients: [%{Email: email, Name: "#{first_name} #{last_name}"}],
      CustomID: custom_id
    })
  end
end
