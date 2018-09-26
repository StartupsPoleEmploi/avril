defmodule Vae.ContactChannel do
  use Phoenix.Channel

  alias Vae.Event
  alias Vae.Mailer.Sender.Mailjet

  @mailjet_conf Application.get_env(:vae, :mailjet)

  def join("contact:send", _message, socket) do
    {:ok, socket}
  end

  def handle_in("contact_request", %{"body" => body}, socket) do
    Map.put_new(body, "contact_delegate", "off")
    |> add_contact_event()
    |> send_messages()

    {:reply, {:ok, %{}}, socket}
  end

  defp add_contact_event(body) do
    Event.create_or_update_job_seeker(%{
      type: "contact_form",
      event: "submitted",
      email: body["email"],
      payload: Kernel.inspect(body)
    })

    body
  end

  defp send_messages(body) do
    messages =
      Enum.reject(
        [
          vae_recap_message(body),
          delegate_message(body)
        ],
        &is_nil/1
      )

    Mailjex.Delivery.send(%{
      Messages: messages
    })
  end

  defp vae_recap_message(body) do
    Map.merge(generic_message(body), %{
      TemplateID: @mailjet_conf.vae_recap_template_id,
      ReplyTo: Mailjet.generic_reply_to(),
      To: Mailjet.build_to(body["email"], body["name"]),
      Attachments: vae_recap(body)
    })
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

  defp delegate_message(%{"contact_delegate" => "on"} = body) do
    Map.merge(generic_message(body), %{
      TemplateID: @mailjet_conf.contact_template_id,
      ReplyTo: %{Email: body["email"], Name: body["name"]},
      To: Mailjet.build_to(body["delegate_email"], body["delegate_name"])
    })
  end

  defp generic_message(body) do
    %{
      TemplateLanguage: true,
      From: Mailjet.generic_from(),
      CustomID: UUID.uuid5(nil, body["email"]),
      Variables: body
    }
  end

  defp delegate_message(_), do: nil
end
