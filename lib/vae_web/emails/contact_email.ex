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

  def delegate_submit(%{
    name: name,
    address: address,
    email: email,
    tel: tel
  } = params) do
    Mailer.build_email(
      "contact/delegate_submit.html",
      :avril,
      :avril,
      %{
        reply_to: {name, email},
        name: name,
        address: address,
        email_address: email,
        tel: tel,
        website: params[:website],
        person_name: params[:person_name],
        comment: params[:comment]
      }
    )
  end

  def delegate_confirm(%{
    name: name,
    address: address,
    email: email,
    tel: tel
  } = params) do
    Mailer.build_email(
      "contact/delegate_confirm.html",
      :avril,
      {name, email},
      %{
        name: name,
        address: address,
        email_address: email,
        tel: tel,
        website: params[:website],
        person_name: params[:person_name],
        comment: params[:comment]
      }
    )
  end
end
