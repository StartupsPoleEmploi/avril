defmodule VaeWeb.ContactEmail do
  alias VaeWeb.Mailer

  def submit(%{
        email: email,
        name: name,
        object: object,
        body: body
      }) do
    Mailer.build_email(
      "contact/submit.html",
      :avril,
      :avril,
      %{
        reply_to: {name, email},
        name: name,
        email_address: email,
        object: object,
        body: body
      }
    )
  end

  def confirm(%{
        email: email,
        name: name,
        object: object,
        body: body
      }) do
    Mailer.build_email(
      "contact/confirm.html",
      :avril,
      {name, email},
      %{
        name: name,
        email: email,
        object: object,
        body: body
      }
    )
  end
end
