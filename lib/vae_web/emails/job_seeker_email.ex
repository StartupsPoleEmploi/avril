defmodule VaeWeb.JobSeekerEmail do
  require Logger

  alias Vae.{JobSeeker, URI}
  alias VaeWeb.Mailer
  alias VaeWeb.Router.Helpers, as: Routes

  # def receive_synthesis(job_seeker, delegate) do
  #   delegate = Repo.preload(delegate, :process)

  #   with(
  #     process when not is_nil(process) <- delegate.process,
  #     {:ok, file} <- StepsPdf.create_pdf_file(delegate.process)
  #   ) do
  #     Mailer.build_email(
  #       "job_seeker/receive_synthesis.html",
  #       :avril,
  #       job_seeker,
  #       %{
  #         subject: "Votre synthèse VAE par Avril - la VAE facile",
  #         attachment:
  #           Swoosh.Attachment.new(file,
  #             filename: "synthese-vae.pdf",
  #             content_type: "application/pdf"
  #           ),
  #         footer_note: :mise_en_relation
  #       }
  #     )
  #   else
  #     _error ->
  #       Logger.warn("No process for delegate #{delegate.name}")
  #   end
  # end

  def campaign(%JobSeeker{id: id, email: email, geolocation: geolocation} = job_seeker, endpoint \\ URI.endpoint()) do
    Mailer.build_email(
      "job_seeker/campaign.html",
      :avril,
      job_seeker,
      %{
        url:
          Routes.root_url(
            endpoint,
            :index,
            utm_campaign: "mj-#{Date.utc_today() |> to_string()}",
            utm_source: (geolocation["administrative"] || []) |> List.first(),
            utm_medium: "email",
            js_id: id
          ),
        image_url:
          Routes.static_url(
            VaeWeb.Endpoint,
            "/images/mon-diplome.jpg"
          ),
        text_center: true,
        job_seeker_id: id,
        job_seeker_msg: true,
        footer_note: :inscrit_de,
        custom_id: UUID.uuid5(nil, email)
      }
    )
  end

  def stock(job_seeker) do
    Mailer.build_email(
      Vae.UserApplications.Config.get_stock_template_id(),
      :avril,
      job_seeker,
      %{
        job_seeker_id: job_seeker.id,
        footer_note: :mise_en_relation
      }
    )
  end
end
