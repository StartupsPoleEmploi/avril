defmodule Vae.Mailer do
  use Bamboo.Mailer, otp_app: :vae
end

defmodule Vae.Email do
  alias Bamboo.Email
  alias Bamboo.MailjetHelper, as: Helper

  def welcome_email() do
    Email.new_email()
    |> Email.to("m.nicolas.zilli@gmail.com")
    |> Email.from("m.nicolas.zilli@gmail.com")
    |> Email.subject("Welcome!!!")
    |> Helper.template("465443")
    |> Helper.template_language(true)
    |> Helper.put_var("foo", "prout")
  end
end
