defmodule VaeWeb.Mailer do
  require Logger

  use Swoosh.Mailer, otp_app: :vae

  use Phoenix.Swoosh,
    view: VaeWeb.EmailView,
    layout: {VaeWeb.EmailView, :layout}

  alias Swoosh.Email
  alias Vae.{Account, JobSeeker, User}

  @config Application.get_env(:vae, VaeWeb.Mailer)
  @override_to System.get_env("DEV_EMAILS")

  def build_email(template_name_or_id, from, to) do
    build_email(template_name_or_id, from, to, %{})
  end

  def build_email(template_name_or_id, from, to, params) do
    %Email{}
    |> to(format_mailer(:to, to))
    |> from(format_mailer(:from, from))
    |> reply_to_if_present_or_from_avril(Map.get(params, :reply_to), from)
    |> custom_id_if_present(Map.get(params, :custom_id))
    |> attach_if_attachment(Map.get(params, :attachment))
    |> render_body_or_template_id(template_name_or_id, params, to)
  end

  def send(email), do: __MODULE__.send(email, [])

  def send(%Email{} = email, config) do
    deliver(email, config)
  end

  def send(emails, config) when is_list(emails) do
    Enum.reduce(emails, {:ok, []}, fn
      email, {:ok, sent_emails} ->
        case __MODULE__.send(email, config) do
          {:ok, %{id: id}} ->
            sent_email = %{
              email
              | provider_options: Map.put(email.provider_options, :id, id)
            }

            {:ok, [sent_email | sent_emails]}

          {:error, _error} ->
            Logger.error(fn ->
              "Error while sending #{inspect(email.to)}"
            end)

            {:ok, sent_emails}

          _error ->
            {:ok, sent_emails}
        end

      _email, error ->
        error
    end)
  end

  defp format_mailer!(:avril_from), do: {@config[:avril_name], @config[:avril_from]}
  defp format_mailer!(:avril_to), do: {@config[:avril_name], @config[:avril_to]}
  defp format_mailer!(%User{} = user), do: Account.formatted_email(user)
  defp format_mailer!(%JobSeeker{} = job_seeker), do: JobSeeker.formatted_email(job_seeker)
  defp format_mailer!(%{name: name, email: email}), do: {name, email}
  defp format_mailer!(%{Name: name, Email: email}), do: {name, email}
  defp format_mailer!(%{email: email}), do: email
  defp format_mailer!(tuple) when is_tuple(tuple), do: tuple
  defp format_mailer!(emails) when is_list(emails), do: Enum.flat_map(emails, &format_mailer!/1)

  defp format_mailer!(email) when is_binary(email) do
    case String.split(email, ",") do
      [] -> nil
      [single] -> format_string_email(single)
      list -> Enum.map(list, &format_string_email/1)
    end
  end

  defp format_mailer!(anything), do: IO.inspect(anything)

  def format_mailer(:to, _anything) when not is_nil(@override_to),
    do: format_mailer!(@override_to)

  def format_mailer(role, :avril) when role in [:to, :reply_to], do: format_mailer!(:avril_to)
  def format_mailer(_role, :avril), do: format_mailer!(:avril_from)

  def format_mailer(role, anything) when role in [:from, :reply_to] do
    case format_mailer!(anything) do
      list when is_list(list) -> List.first(list)
      no_list -> no_list
    end
  end

  def format_mailer(_role, anything), do: format_mailer!(anything)

  defp format_string_email(string_email) do
    case Regex.named_captures(~r/(?<Name>.*) ?\<(?<Email>.*)\>/U, string_email) do
      %{"Name" => name, "Email" => email} -> {name, email}
      nil -> string_email
    end
  end

  defp reply_to_if_present_or_from_avril(email, reply_to, _from) when not is_nil(reply_to),
    do: reply_to(email, format_mailer(:reply_to, reply_to))

  defp reply_to_if_present_or_from_avril(email, _reply_to, :avril),
    do: reply_to(email, format_mailer(:reply_to, :avril))

  defp reply_to_if_present_or_from_avril(email, _, _),
    do: email

  defp custom_id_if_present(email, nil), do: email

  defp custom_id_if_present(email, custom_id),
    do: put_provider_option(email, :custom_id, custom_id)

  defp attach_if_attachment(email, nil), do: email
  defp attach_if_attachment(email, attachment), do: attachment(email, attachment)

  defp render_body_or_template_id(email, template_name_or_id, params, to) do
    if is_integer(template_name_or_id) do
      render_template(email, template_name_or_id, params)
    else
      render_body_and_subject(email, template_name_or_id, params, to)
    end
  end

  defp render_template(email, template_id, params) do
    email
    |> put_provider_option(:template_id, template_id)
    |> put_provider_option(:variables, params)
    |> put_provider_option(:template_error_deliver, @config[:template_error_deliver])
    |> put_provider_option(
      :template_error_reporting,
      format_mailer(:to, @config[:template_error_to])
    )
  end

  defp render_body_and_subject(email, template_name, params, to) do
    email
    |> render_body(template_name, params)
    |> render_text_and_extract_subject(template_name, params, to)
  end

  defp render_text_and_extract_subject(email, _template_name, params, to) do
    # {:ok, file_content} = File.read(IO.inspect("#{Application.app_dir(:vae)}/web/templates/email/#{template_name}.md"))
    # processed_content = EEx.eval_string(file_content, params)
    # {subject, rest} = String.split(file_content, "\n---\n", parts: 2)
    # email
    # |> subject(subject)
    # |> Map.put(:text_body, rest)
    subject = "#{environment_prefix(to)}#{Map.get(params, :subject)}" |> String.slice(0, 255)
    email |> subject(subject)
  end

  defp environment_prefix(to) do
    if @override_to do
      "[Avril][#{Mix.env()}] #{inspect(format_mailer!(to))} - "
    end
  end

  # defp _extract_subject(_template_name) do
  #   "Coucou"
  #   # %{"subject" => subject} = Regex.named_captures(~r/\[SUJET\]: # \((?<subject>.*)\)/, file_content)
  #   # subject
  # end

  # defp _render_markdown_bodies(email, template_name, params) do
  #   email
  #     # |> Map.put(:"html_body", "Hello you")
  #   |> Map.put(:html_body, Phoenix.View.render_to_string(VaeWeb.EmailView, template_name, params))
  #   # |> Map.put(:"text_body", Phoenix.View.render_to_string(VaeWeb.EmailView, template_name, params))
  # end
end
