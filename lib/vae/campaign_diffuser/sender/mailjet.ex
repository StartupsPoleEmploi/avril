# defmodule Vae.Mailer.Sender.Mailjet do
#   @behaviour Vae.Mailer.Sender

#   alias Vae.Mailer.Email

#   @mailjet_conf Application.get_env(:vae, :mailjet)

#   def send(%Email{} = email) do
#     build_message(email)
#     |> do_send()
#     |> case do
#       {:ok, %{"Messages" => messages}} ->
#         Enum.map(messages, fn message ->
#           %{email | state: String.to_atom(message["Status"])}
#         end)

#       {:error, %{"Messages" => errors}} ->
#         Enum.map(errors, fn error ->
#           %{email | state: String.to_atom(error["Status"]), errors: error["Errors"]}
#         end)
#     end
#   end

#   defp build_utm_source(job_seeker) do
#     job_seeker.geolocation["administrative"] |> List.first()
#   end

#   defp build_message(email, utm_campaign \\ "mj-#{Date.utc_today() |> to_string()}")

#   defp build_message(
#          %Email{
#            custom_id: custom_id,
#            job_seeker: nil,
#            template_id: template_id,
#            to: to,
#            vars: vars
#          },
#          _utm_campaign
#        ) do
#     %{
#       TemplateID: template_id,
#       TemplateLanguage: true,
#       TemplateErrorDeliver: Application.get_env(:vae, :mailjet_template_error_deliver),
#       TemplateErrorReporting: Application.get_env(:vae, :mailjet_template_error_reporting),
#       From: generic_from(),
#       ReplyTo: avril_email(),
#       Variables: vars,
#       To: build_to(to),
#       CustomID: custom_id
#     }
#   end

#   defp build_message(
#          %Email{custom_id: custom_id, job_seeker: job_seeker},
#          utm_campaign
#        ) do
#     with email when not is_nil(email) <- get_email(job_seeker),
#          first_name <- get_first_name(job_seeker),
#          last_name <- get_last_name(job_seeker),
#          utm_source <- build_utm_source(job_seeker) do
#       %{
#         TemplateID: @mailjet_conf[:campaign_template_id],
#         TemplateLanguage: true,
#         TemplateErrorDeliver: Application.get_env(:vae, :mailjet_template_error_deliver),
#         TemplateErrorReporting: Application.get_env(:vae, :mailjet_template_error_reporting),
#         From: generic_from(),
#         ReplyTo: avril_email(),
#         Variables: %{utm_campaign: utm_campaign, utm_source: utm_source, js_id: job_seeker.id},
#         To: build_to(%{Email: email, Name: "#{first_name} #{last_name}"}),
#         CustomID: custom_id
#       }
#     else
#       _ -> nil
#     end
#   end

#   defp do_send(message) do
#     Mailjex.Delivery.send(%{
#       Messages: [message]
#     })
#   end

#   defp get_email(job_seeker), do: get_in(job_seeker, [Access.key(:email)])
#   defp get_first_name(job_seeker), do: get_in(job_seeker, [Access.key(:first_name)])
#   defp get_last_name(job_seeker), do: get_in(job_seeker, [Access.key(:last_name)])

#   def generic_from() do
#     %{
#       Email: @mailjet_conf[:from_email],
#       Name: @mailjet_conf[:from_name]
#     }
#   end

#   def avril_email() do
#     %{
#       Email: "avril@pole-emploi.fr",
#       Name: "Avril"
#     }
#   end

#   def build_to(to) do
#     format_receiver(Keyword.get(@mailjet_conf, :override_to, to))
#   end

#   # Accepted formats:
#   # "email@example.com"
#   # ["email@example.com", "other-email@example.com"]
#   # "Full Name <email@example.com>"
#   # ["Full Name <email@example.com>", "Other Name <other-email@example.com>"]
#   # %{Email: "email@example.com"}
#   # [%{Email: "email@example.com"}, %{Email: "other-email@example.com"}]
#   defp format_receiver(%{Email: _email} = params), do: List.wrap(params)
#   defp format_receiver(email) when is_binary(email), do: email |> String.split(",") |> Enum.map(&format_string_email/1)
#   defp format_receiver(emails) when is_list(emails), do: Enum.flat_map(emails, &format_receiver/1)

#   defp format_string_email(string_email) do
#     (Regex.named_captures(~r/(?<Name>.*) ?\<(?<Email>.*)\>/U, string_email) || %{"Email" => string_email})
#     |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)
#   end
# end
