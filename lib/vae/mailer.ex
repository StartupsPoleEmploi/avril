defmodule Vae.Email do
  def welcome_email() do
    Mailjex.Delivery.send(%{
      FromEmail: "m.nicolas.zilli@gmail.com",
      FromName: "L'équipe Avril",
      Subject: "Test envoi email",
      "MJ-TemplateID": "465443",
      "MJ-TemplateLanguage": true,
      Vars: %{foo: "Prout"},
      Recipients: [%{Email: "m.nicolas.zilli@gmail.com"}]
    })
  end

  def send_campain_email(%{email: email, first_name: first_name, last_name: last_name}) do
    Mailjex.Delivery.send(%{
      FromEmail: "m.nicolas.zilli@gmail.com",
      FromName: "Votre conseiller VAE",
      Subject: "Votre VAE",
      "MJ-TemplateID": "480897",
      "MJ-TemplateLanguage": true,
      # Vars: %{foo: "Prout"},
      Recipients: [%{Email: email, Name: "#{first_name} #{last_name}"}]
    })
  end
end
