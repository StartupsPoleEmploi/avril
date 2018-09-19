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
            delegate_city: body["delegate_city"],
            delegate_name: body["delegate_name"],
            delegate_address: body["delegate_address"],
            delegate_phone_number: body["delegate_phone_number"],
            job: body["job"],
            certification: body["certification"]
          },
          To:
            Map.get(@mailjet_conf, :override_to, [
              %{Email: body["email"], Name: body["name"]}
            ]),
          CustomID: UUID.uuid5(nil, body["email"]),
          Attachments: vae_recap(body)
        }
      ]
    })

    {:reply, {:ok, %{}}, socket}
  end

  defp vae_recap(%{"process" => id}) do
    with process when not is_nil(process) <- Vae.Repo.get(Vae.Process, id),
         {:ok, file} <- Vae.StepsPdf.create_pdf(process) do
      [
        %{
          ContentType: "application/pdf",
          Filename: "etapes.pdf",
          Base64Content: Base.encode64(file)
        }
      ]
    else
      []
    end
  end
end
