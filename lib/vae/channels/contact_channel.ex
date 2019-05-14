defmodule Vae.ContactChannel do
  use Phoenix.Channel

  alias Vae.Event
  alias Vae.Mailer.Sender.Mailjet
  alias Vae.Repo
  alias Vae.Delegate
  alias Vae.Places

  @mailjet_conf Application.get_env(:vae, :mailjet)

  def join("contact:send", _message, socket) do
    {:ok, socket}
  end

  def handle_in("contact_request", %{"body" => body}, socket) do
    delegate_info = get_delegate_info(body)

    body
    |> Map.merge(delegate_info)
    |> Map.put_new("contact_delegate", "off")
    |> Map.put_new("booklet_1", "off")
    |> add_contact_event()
    |> send_messages()

    {:reply, {:ok, %{}}, socket}
  end

  defp get_delegate_info(body) do
    delegate = Repo.get(Delegate, body["delegate"])

    %{
      "delegate_city" => Places.get_city(delegate.geolocation),
      "delegate_name" => delegate.name,
      "delegate_email" => delegate.email,
      "delegate_address" => delegate.address,
      "delegate_phone_number" => delegate.telephone,
      "delegate_website" => delegate.website,
      "delegate_person_name" => delegate.person_name,
      "delegate_is_asp" => Delegate.is_asp?(delegate),
      "process" => delegate.process_id
    }
    |> Enum.filter(fn {_, v} -> v != nil end)
    |> Enum.into(%{})
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

    Mailjex.Delivery.send(%{Messages: messages})
  end

  defp vae_recap_message(%{"contact_delegate" => "on", "delegate_email" => ""} = body) do
    body
    |> Map.put("contact_delegate", "off")
    |> vae_recap_message()
  end

  defp vae_recap_message(body) do
    body
    |> generic_message()
    |> Map.merge(%{
      TemplateID: if body["delegate_is_asp"], do: @mailjet_conf[:asp_vae_recap_template_id], else: @mailjet_conf[:vae_recap_template_id],
      ReplyTo: Mailjet.avril_email(),
      To: Mailjet.build_to(%{Email: body["email"], Name: get_name(body)}),
      Attachments:
        vae_recap_attachments(body)
        |> add_booklet_1(body)
    })
  end

  defp vae_recap_attachments(%{"process" => id}) do
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

  defp add_booklet_1(attachments, %{"booklet_1" => "on"}) do
    attachments ++
      [
        %{
          ContentType: "application/pdf",
          Filename: "dossier_inscription.pdf",
          Base64Content: Base.encode64(File.read!("priv/cerfa_12818-02.pdf"))
        },
        %{
          ContentType: "application/pdf",
          Filename: "notice.pdf",
          Base64Content: Base.encode64(File.read!("priv/notice_51260#02.pdf"))
        }
      ]
  end

  defp add_booklet_1(attachments, _body) do
    attachments
  end

  defp delegate_message(%{"contact_delegate" => "on", "delegate_email" => ""} = body) do
    body
    |> generic_message()
    |> Map.merge(%{
      TemplateID: @mailjet_conf[:contact_template_id],
      ReplyTo: %{Email: body["email"], Name: get_name(body)},
      To: Mailjet.build_to(Mailjet.avril_email())
    })
  end

  defp delegate_message(%{"contact_delegate" => "on", "delegate_email" => _} = body) do
    body
    |> generic_message()
    |> Map.merge(%{
      TemplateID: @mailjet_conf[:contact_template_id],
      ReplyTo: %{Email: body["email"], Name: get_name(body)},
      To: Mailjet.build_to(%{Email: body["delegate_email"], Name: body["delegate_name"]})
    })
  end

  defp delegate_message(_), do: nil

  defp generic_message(body) do
    %{
      From: Mailjet.generic_from(),
      CustomID: UUID.uuid5(nil, body["email"]),
      TemplateLanguage: true,
      TemplateErrorDeliver: Application.get_env(:vae, :mailjet_template_error_deliver),
      TemplateErrorReporting: Application.get_env(:vae, :mailjet_template_error_reporting),
      Variables: body
    }
  end

  defp get_name(body), do: "#{body["first_name"]} #{body["last_name"]}"
end
