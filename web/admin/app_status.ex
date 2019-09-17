defmodule Vae.ExAdmin.AppStatus do
  use ExAdmin.Register
  import Ecto.Query

  register_page "app-status" do
    menu priority: 2, label: "Bandeau informatif"
    content do
      div [{:id, "status-editor"}, {:"data-token", Plug.CSRFProtection.get_csrf_token()}]
    end
  end
end