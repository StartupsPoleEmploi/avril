defmodule Vae.ContactChannel do
  use Phoenix.Channel

  @mailjet_conf Application.get_env(:vae, :mailjet)

  def join("contact:send", _message, socket) do
    {:ok, socket}
  end

  def handle_in("contact_request", %{"body" => body}, socket) do
    body_updated = Map.put_new(body, "contact_delegate", "off")

    messages =
      Enum.reject(
        [
          vae_recap_message(body_updated),
          delegate_message(body_updated)
        ],
        &is_nil/1
      )

    Mailjex.Delivery.send(%{
      Messages: messages
    })

    {:reply, {:ok, %{}}, socket}
  end

  defp vae_recap_message(body) do
    %{
      TemplateID: @mailjet_conf.vae_recap_template_id,
      TemplateLanguage: true,
      From: %{
        Email: @mailjet_conf.from_email,
        Name: @mailjet_conf.from_name
      },
      Variables: body,
      To:
        Map.get(@mailjet_conf, :override_to, [
          %{Email: body["email"], Name: body["name"]}
        ]),
      CustomID: UUID.uuid5(nil, body["email"]),
      Attachments: vae_recap(body)
    }
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

  defp delegate_message(body = %{"contact_delegate" => "on"}) do
    %{
      TemplateID: @mailjet_conf.contact_template_id,
      TemplateLanguage: true,
      From: %{
        Email: @mailjet_conf.from_email,
        Name: @mailjet_conf.from_name
      },
      ReplyTo: %{
        Email: body["email"],
        Name: body["name"]
      },
      Variables: body,
      To:
        Map.get(@mailjet_conf, :override_to, [
          %{Email: Map.get(body, "email", "avril@pole-emploi.fr"), Name: body["delegate_name"]}
        ]),
      CustomID: UUID.uuid5(nil, body["email"])
    }
  end

  defp delegate_message(_), do: nil
end
