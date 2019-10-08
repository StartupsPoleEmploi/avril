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

  @mailjet_conf Application.get_env(:vae, :mailjet)

  def build_email(template_name_or_id, from, to) do
    build_email(template_name_or_id, from, to, %{})
  end

  def build_email(template_name_or_id, from, to, params) do
    %Email{}
    |> from(format_mailer(:from, from))
    |> to(format_mailer(:to, to))
    |> reply_to_if_present(Map.get(params, :reply_to))
    |> attach_if_attachment(Map.get(params, :attachment))
    |> render_body_or_template_id(template_name_or_id, params)
  end

  def send(%Email{} = email, config \\ []) do
    deliver(email, config)
  end

  def send(emails, config \\ []) when is_list(emails) do
    Enum.reduce(emails, {:ok, []}, fn
      email, {:ok, sent_emails} ->
        case send(email, config) do
          {:ok, sent_email} -> {:ok, [sent_email | sent_emails]}
          error -> error
        end
      _email, error -> error
    end)
  end

  defp format_mailer!(:avril), do: @avril_email
  defp format_mailer!(%User{} = user), do: User.formatted_email(user)
  defp format_mailer!(%JobSeeker{} = job_seeker), do: User.formatted_email(job_seeker)
  defp format_mailer!(%{name: name, email: email}), do: {name, email}
  defp format_mailer!(%{email: email}), do: email
  defp format_mailer!(email) when is_binary(email), do: format_string_email(email)
  defp format_mailer!(tuple) when is_tuple(tuple), do: tuple
  defp format_mailer!(emails) when is_list(emails), do: Enum.flat_map(emails, &format_mailer!/1)
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

  defp render_body_or_template_id(email, template_name_or_id, params) do
    if is_integer(template_name_or_id) || (is_atom(template_name_or_id) && @mailjet_conf[template_name_or_id]) do
      render_template(email, template_name_or_id, params)
    else
      render_body_and_subject(email, template_name_or_id, params)
    end
  end

  defp render_template(email, template_id, params) do
    email
      |> put_provider_option(:template_id, template_id)
      |> put_provider_option(:variables, params)
      |> put_provider_option(:template_error_deliver, Application.get_env(:vae, :mailjet_template_error_deliver))
      |> put_provider_option(:template_error_reporting, Application.get_env(:vae, :mailjet_template_error_reporting))
  end

  defp render_body_and_subject(email, template_name, params) do
    email
      |> render_body(template_name, params)
      |> render_text_and_extract_subject(template_name, params)
  end

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