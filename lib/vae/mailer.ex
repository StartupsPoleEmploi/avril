defmodule Vae.Email do
  def welcome_email() do
    Mailjex.Delivery.send(%{
      FromEmail: "avril@pole-emploi.fr",
      FromName: "L'équipe Avril",
      "MJ-TemplateID": "475460",
      "MJ-TemplateLanguage": true,
      Recipients: [%{Email: "m.nicolas.zilli@gmail.com"}, %{Email: "nresnikow@gmail.com"}]
    })
  end

  def send_campain_email(
        %{email: email, first_name: first_name, last_name: last_name},
        utm_campaign \\ "lancement",
        utm_source
      ) do
    Mailjex.Delivery.send(%{
      FromEmail: "avril@pole-emploi.fr",
      FromName: "L'équipe Avril",
      "MJ-TemplateID": "475460",
      "MJ-TemplateLanguage": true,
      Vars: %{utm_campaign: utm_campaign, utm_source: utm_source},
      Recipients: [%{Email: email, Name: "#{first_name} #{last_name}"}]
    })
  end
end
