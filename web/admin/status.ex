defmodule Vae.ExAdmin.Status do
  use ExAdmin.Register
  import Ecto.Query

  register_page "Status" do
    menu priority: 2, label: "Status"
    content do
      div [{:id, "status-editor"}, {:"data-token", Plug.CSRFProtection.get_csrf_token()}]
    end
  end
end