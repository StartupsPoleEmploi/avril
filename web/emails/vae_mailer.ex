defmodule Vae.Mailer do
  use Swoosh.Mailer, otp_app: :vae
  use Phoenix.Swoosh,
    view: Vae.EmailView,
    layout: {Vae.LayoutView, :email}
  alias Swoosh.Email
  alias Vae.{User}

  @avril_email {
    Application.get_env(:vae, :mailjet)[:from_name],
    Application.get_env(:vae, :mailjet)[:from_email]
  }

  @override_email System.get_env("DEV_EMAILS")

  def send_email(template_name, from, to) do
    send_email(template_name, from, to, %{})
  end

  def send_email(template_name, from, to, params) do
    %Email{}
    |> from(format_mailer(:from, from))
    |> to(format_mailer(:to, to))
    |> reply_to_if_present(Map.get(params, :reply_to))
    |> attach_if_attachment(Map.get(params, :attachment))
    |> render_body(template_name, params)
    |> render_text_and_extract_subject(template_name, params)
    # |> __MODULE__.deliver()
  end

  def deliver_multi(emails, config \\ []) when is_list(emails) do
    Enum.reduce(emails, {:ok, []}, fn
      email, {:ok, sent_emails} ->
        case deliver(email, config) do
          {:ok, sent_email} -> {:ok, [sent_email | sent_emails]}
          error -> error
        end
      _email, error -> error
    end)
  end

  defp format_mailer!(:avril), do: @avril_email
  defp format_mailer!(%User{} = user), do: User.formatted_email(user)
  defp format_mailer!(%{name: name, email: email}), do: {name, email}
  defp format_mailer!(%{email: email}), do: email
  defp format_mailer!(email) when is_binary(email), do: format_string_email(email)
  defp format_mailer!(tuple) when is_tuple(tuple), do: tuple
  defp format_mailer!(anything), do: IO.inspect(anything)

  defp format_mailer(:to, _anything) when not is_nil(@override_email), do: format_mailer!(@override_email)
  defp format_mailer(_any_role, anything), do: format_mailer!(anything)

  defp format_string_email(string_email) do
    case Regex.named_captures(~r/(?<Name>.*) ?\<(?<Email>.*)\>/U, string_email) do
      %{"Name" => name, "Email" => email} -> {name, email}
      nil -> string_email
    end
  end

  defp reply_to_if_present(email, nil), do: email
  defp reply_to_if_present(email, reply_to), do: reply_to(email, format_mailer(:reply_to, reply_to))

  defp attach_if_attachment(email, nil), do: email
  defp attach_if_attachment(email, attachment), do: attachment(email, attachment)

  defp render_text_and_extract_subject(email, _template_name, params) do
    # {:ok, file_content} = File.read(IO.inspect("#{Application.app_dir(:vae)}/web/templates/email/#{template_name}.md"))
    # processed_content = EEx.eval_string(file_content, params)
    # {subject, rest} = String.split(file_content, "\n---\n", parts: 2)
    # email
    # |> subject(subject)
    # |> Map.put(:text_body, rest)
    email |> subject(Map.get(params, :subject))
  end

  # defp _extract_subject(_template_name) do
  #   "Coucou"
  #   # %{"subject" => subject} = Regex.named_captures(~r/\[SUJET\]: # \((?<subject>.*)\)/, file_content)
  #   # subject
  # end

  # defp _render_markdown_bodies(email, template_name, params) do
  #   email
  #     # |> Map.put(:"html_body", "Hello you")
  #   |> Map.put(:html_body, Phoenix.View.render_to_string(Vae.EmailView, template_name, params))
  #   # |> Map.put(:"text_body", Phoenix.View.render_to_string(Vae.EmailView, template_name, params))
  # end

end