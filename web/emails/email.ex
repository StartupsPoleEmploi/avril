defmodule Vae.Email do
  alias Vae.Mailer.Sender.Mailjet
  @mailjet_conf Application.get_env(:vae, :mailjet)

  def send(email_params) do
    Mailjex.Delivery.send(%{Messages: email_params})
  end

  def generic_fields(template_id, to, variables\\%{}) do
    IO.inspect(%{
      From: Mailjet.generic_from(),
      CustomID: UUID.uuid5(nil, to.email),
      TemplateLanguage: true,
      TemplateErrorDeliver: Application.get_env(:vae, :mailjet_template_error_deliver),
      TemplateErrorReporting: Application.get_env(:vae, :mailjet_template_error_reporting),
      Variables: variables,
      TemplateID: @mailjet_conf[template_id],
      ReplyTo: Mailjet.build_to(%{Email: to.email, Name: to.name}),
      To: Mailjet.build_to(%{Email: to.email, Name: to.name})
    })
  end

end