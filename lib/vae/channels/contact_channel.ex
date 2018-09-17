defmodule Vae.ContactChannel do
  use Phoenix.Channel

  @mailjet_conf Application.get_env(:vae, :mailjet)

  def join("contact:send", _message, socket) do
    {:ok, socket}
  end

  def handle_in("contact_request", %{"body" => body}, socket) do
    Mailjex.Delivery.send(%{
      Messages: [
        %{
          TemplateID: @mailjet_conf.vae_recap_template_id,
          TemplateLanguage: true,
          From: %{
            Email: @mailjet_conf.from_email,
            Name: "📜 Avril"
          },
          Variables: %{
            delegate_city: Map.get(body, "delegate_city", "????"),
            delegate_name: Map.get(body, "delegate_name", "????"),
            delegate_address: Map.get(body, "delegate_address", "????"),
            delegate_phone_number: Map.get(body, "delegate_phone_number", "????"),
            job: Map.get(body, "job", "????"),
            certification: Map.get(body, "certification", "????"),
            process_path: Map.get(body, "process_path", "????")
          },
          To:
            Map.get(@mailjet_conf, :override_to, [
              %{Email: body["email"], Name: body["name"]}
            ]),
          CustomID: UUID.uuid5(nil, body["email"])
        }
      ]
    })

    {:reply, {:ok, %{}}, socket}
  end
end
