defmodule VaeWeb.JobSeekerEmail do
  # NOT USED ANYMORE

  # require Logger

  # alias Vae.{JobSeeker, URI}
  # alias VaeWeb.Mailer
  # alias VaeWeb.Router.Helpers, as: Routes

  # def campaign(%JobSeeker{id: id, email: email} = job_seeker, endpoint \\ URI.endpoint()) do
  #   Mailer.build_email(
  #     "job_seeker/campaign.html",
  #     :avril,
  #     job_seeker,
  #     %{
  #       url:
  #         Routes.root_url(
  #           endpoint,
  #           :index,
  #           at_campaign: "mail_hebdo_de_primo",
  #           at_send_date: Date.utc_today() |> Timex.format!("{YYYY}0{M}0{D}"),
  #           at_link: "call_to_action",
  #           at_medium: "email",
  #           at_emailtype: "acquisition"
  #         ),
  #       image_url: URI.static_url(endpoint, "/images/mon-diplome.jpg"),
  #       text_center: true,
  #       job_seeker_id: id,
  #       job_seeker_msg: true,
  #       footer_note: :inscrit_de,
  #       can_unsubscribe: true,
  #       custom_id: UUID.uuid5(nil, email)
  #     }
  #   )
  # end
end
