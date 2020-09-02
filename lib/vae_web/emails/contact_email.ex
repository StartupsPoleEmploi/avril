defmodule VaeWeb.ContactEmail do
  alias VaeWeb.Mailer

  def submit(%{
        "email" => email,
        "name" => name,
        "body" => body
      } = params) do
    Mailer.build_email(
      "contact/submit.html",
      :avril,
      :avril,
      %{
        reply_to: {name, email},
        name: name,
        email_address: email,
        object: params["object"],
        body: body
      }
    )
  end

  def confirm(%{
        "email" => email,
        "name" => name,
        "body" => body
      } = params) do
    Mailer.build_email(
      "contact/confirm.html",
      :avril,
      {name, email},
      %{
        name: name,
        email: email,
        object: params["object"],
        body: body
      }
    )
  end
end
