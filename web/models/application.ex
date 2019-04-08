defmodule Vae.Application do
  use Vae.Web, :model

  alias Vae.Repo
  alias Vae.Mailer.Sender.Mailjet


  schema "applications" do
    field :submitted_at, :utc_datetime
    belongs_to :user, Vae.User, foreign_key: :user_id
    belongs_to :delegate, Vae.Delegate, foreign_key: :delegate_id
    belongs_to :certification, Vae.Certification, foreign_key: :certification_id

    timestamps()
  end

  @fields ~w(user_id delegate_id certification_id submitted_at)a

  def changeset(struct, params \\%{}) do
    struct
    |> cast(params, @fields)
  end

  def create_with_params(params) do
    case Repo.insert(__MODULE__.changeset(%__MODULE__{}, params)) do
      {:ok, application} -> application
      error -> nil
    end
  end

  def generate_delegate_access(application) do
    case Repo.update(__MODULE__.changeset(application, %{
      delegate_access_hash: generate_hash(64),
      delegate_access_refreshed_at: DateTime.utc_now(),
    })) do
      {:ok, application} -> send_messages(application)
      error -> error
    end
  end

  def send_messages(application) do

  #   # Mailjex.Delivery.send(%{Messages: messages})
  end

  # defp delegate_message(%{"contact_delegate" => "on", "delegate_email" => ""} = body) do
  #   body
  #   |> generic_message()
  #   |> Map.merge(%{
  #     TemplateID: @mailjet_conf.contact_template_id,
  #     ReplyTo: %{Email: body["email"], Name: get_name(body)},
  #     To: Mailjet.build_to(Mailjet.avril_email())
  #   })
  # end

  # defp delegate_message(%{"contact_delegate" => "on", "delegate_email" => _} = body) do
  #   (%{
  #     From: Mailjet.generic_from(),
  #     CustomID: UUID.uuid5(nil, body["email"]),
  #     TemplateLanguage: true,
  #     TemplateErrorDeliver: Application.get_env(:vae, :mailjet_template_error_deliver),
  #     TemplateErrorReporting: Application.get_env(:vae, :mailjet_template_error_reporting),
  #     Variables: body
  #     TemplateID: @mailjet_conf.contact_template_id,
  #     ReplyTo: %{Email: body["email"], Name: get_name(body)},
  #     To: Mailjet.build_to(%{Email: body["delegate_email"], Name: body["delegate_name"]})
  #   })
  # end


  defp generate_hash(length) do
    :crypto.strong_rand_bytes(length) |> Base.url_encode64 |> binary_part(0, length)
  end
end
