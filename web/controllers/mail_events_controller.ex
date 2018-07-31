defmodule Vae.MailEventsController do
  use Vae.Web, :controller

  alias Vae.Mailer

  def new_event(conn, params) do
    Mailer.handle_events(params["_json"])
    send_resp(conn, 200, "")
  end
end
