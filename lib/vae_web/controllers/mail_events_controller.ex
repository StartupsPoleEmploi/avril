defmodule VaeWeb.MailEventsController do
  require Logger
  use VaeWeb, :controller

  def new_event(conn, params) do
    with {:init, pid} <- {:init, Vae.Event.Api.new_email_event()},
         {:handle, _job_seekers} <-
           {:handle, Vae.Event.Api.handle_email_event(pid, params["_json"])},
         {:terminate, :ok} <- {:terminate, Vae.Event.Api.terminate(pid)} do
      send_resp(conn, 200, "")
    else
      {key, err} ->
        Logger.error(fn -> "Error while #{key}: #{inspect(err)}" end)
        # For now, we log and return 200, later, we'll see what we do
        send_resp(conn, 200, "")
    end
  end
end
