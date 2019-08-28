defmodule Vae.Email do
  alias Vae.Mailer.Sender.Mailjet
  @mailjet_conf Application.get_env(:vae, :mailjet)

  def send(email_params) do
    Mailjex.Delivery.send(%{Messages: email_params})
  end

  def generic_fields(template_id, to, variables \\ %{}) do
    %{
      From: Mailjet.generic_from(),
      CustomID: UUID.uuid5(nil, to.email),
      TemplateLanguage: true,
      TemplateErrorDeliver: Application.get_env(:vae, :mailjet_template_error_deliver),
      TemplateErrorReporting: Application.get_env(:vae, :mailjet_template_error_reporting),
      Variables: variables,
      TemplateID: @mailjet_conf[template_id],
      To: Mailjet.build_to(%{Email: to.email, Name: to.name})
    }
  end

  def contact_fields(%{
      "email" => email,
      "name" => name,
      "object" => object,
      "body" => body
    }) do
    [%{
      ReplyTo: %{
        Email: email,
        Name: name
      },
      From: %{
        Email: "contact@avril.pole-emploi.fr",
        Name: "Avril"
      },
      CustomID: UUID.uuid5(nil, "#{email} #{object}"),
      TemplateLanguage: true,
      TemplateErrorDeliver: Application.get_env(:vae, :mailjet_template_error_deliver),
      TemplateErrorReporting: Application.get_env(:vae, :mailjet_template_error_reporting),
      Variables: %{
        email: email,
        name: name,
        object: object,
        body: body
      },
      Subject: "[Contact Avril] #{object}",
      TemplateID: @mailjet_conf[:avril_contact_template_id],
      To: Mailjet.build_to(%{Email: "contact@avril.pole-emploi.fr", Name: "Avril"})
    }, %{
      ReplyTo: %{
        Email: "contact@avril.pole-emploi.fr",
        Name: "Avril"
      },
      From: %{
        Email: "contact@avril.pole-emploi.fr",
        Name: "Avril"
      },
      CustomID: UUID.uuid5(nil, "#{email} #{object} COPY"),
      TemplateLanguage: true,
      TemplateErrorDeliver: Application.get_env(:vae, :mailjet_template_error_deliver),
      TemplateErrorReporting: Application.get_env(:vae, :mailjet_template_error_reporting),
      Variables: %{
        email: email,
        name: name,
        object: object,
        body: body
      },
      Subject: "[Contact Avril] Votre message: #{object}",
      TemplateID: @mailjet_conf[:avril_contact_template_id],
      To: Mailjet.build_to(%{Email: email, Name: name})
    }]
  end
end
