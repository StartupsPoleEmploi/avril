defmodule VaeWeb.ContactEmail do
  alias VaeWeb.Mailer

  def submit(%{
        "email" => email,
        "name" => name,
        "object" => object,
        "body" => body
      }) do
    Mailer.build_email(
      "contact/submit.html",
      :avril,
      :avril,
      %{
        subject: "[Avril - la VAE Facile] #{object}",
        reply_to: {name, email},
        name: name,
        email_address: email,
        object: object,
        body: body
      }
    )
  end

  def confirm(%{
        "email" => email,
        "name" => name,
        "object" => object,
        "body" => body
      }) do
    Mailer.build_email(
      "contact/confirm.html",
      :avril,
      {name, email},
      %{
        subject: "[Avril - la VAE Facile] Confirmation de votre demande de contact : #{object}",
        name: name,
        email: email,
        object: object,
        body: body
      }
    )
  end
end
