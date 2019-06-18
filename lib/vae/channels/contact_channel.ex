defmodule Vae.ContactChannel do
  require Logger
  use Phoenix.Channel

  alias Vae.Application, as: JsApplication
  alias Vae.Certification
  alias Vae.Delegate
  alias Vae.Event
  alias Vae.Mailer.Sender.Mailjet
  alias Vae.Places
  alias Vae.Repo

  @mailjet_conf Application.get_env(:vae, :mailjet)

  def join("contact:send", _message, socket) do
    try do
      {:ok, socket}
    rescue
      e ->
        Logger.error(fn -> inspect(e) end)
        {:error, "Une erreur est survenue."}
    end
  end

  def handle_in("contact_request", %{"body" => body}, socket) do
    try do
      delegate_info = get_delegate_info(body)

      body
      |> Map.merge(delegate_info)
      |> Map.put_new("contact_delegate", "off")
      |> Map.put_new("booklet_1", "off")
      |> add_contact_event()
      |> send_messages()

      {:reply, {:ok, %{}}, socket}
    rescue
      e ->
        Logger.error(fn -> inspect(e) end)
        {:reply, {:error, "Une erreur est survenue, merci de réessayer plus tard."}}
    end
  end

  defp get_delegate_info(body) do
    delegate = Repo.get(Delegate, body["delegate"])

    Map.merge(body, %{
      "delegate_city" => Places.get_city(delegate.geolocation),
      "delegate_name" => delegate.name,
      "delegate_email" => delegate.email,
      "delegate_address" => delegate.address,
      "delegate_phone_number" => delegate.telephone,
      "delegate_website" => delegate.website,
      "delegate_person_name" => delegate.person_name,
      "delegate_is_asp" => Delegate.is_asp?(delegate),
      "delegate_external_subscription_link" => Delegate.external_subscription_link(delegate),
      "process" => delegate.process_id
    })
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
    |> maybe_create_application(body)
  end

  defp maybe_create_application(job_seeker, %{"contact_delegate" => "on"} = body) do
    with user <- get_or_create_user_for_application(job_seeker, body),
         certification <- find_certification(body["certification"]) do
      create_or_update_application(user, certification, body["delegate"])
    end

    body
  end

  defp maybe_create_application(_job_seeker, body), do: body

  defp get_or_create_user_for_application(job_seeker, body) do
    tmp_password = "AVRIL_#{UUID.uuid5(nil, body["email"])}_TMP_PASSWORD"

    params =
      Map.take(body, ["first_name", "last_name", "email", "phone_number"])
      |> Map.merge(%{
        "job_seeker" => job_seeker,
        "password" => tmp_password,
        "password_confirmation" => tmp_password
      })

    Repo.get_by(Vae.User, email: body["email"]) ||
      %Vae.User{}
      |> Vae.User.changeset(params)
      |> Repo.insert!()
  end

  defp find_certification(certification_label) do
    Certification.find_by_acronym_and_label(certification_label)
  end

  defp create_or_update_application(user, certification, delegate) do
    JsApplication.find_or_create_with_params(%{
      user_id: user.id,
      delegate_id: delegate,
      certification_id: certification.id
    })
    |> JsApplication.submitted_now()
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
      TemplateID:
        cond do
          body["delegate_is_asp"] -> @mailjet_conf[:asp_vae_recap_template_id]
          body["delegate_external_subscription_link"] -> @mailjet_conf[:dava_vae_recap_template_id]
          true -> @mailjet_conf[:vae_recap_template_id]
        end,
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
