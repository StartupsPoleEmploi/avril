defmodule Vae.JobSeekerEmail do
  require Logger

  alias Vae.{Mailer, Repo, StepsPdf}
  alias Vae.Router.Helpers, as: Routes

  def receive_synthesis(job_seeker, delegate) do
    delegate = Repo.preload(delegate, :process)

    with(
      process when not is_nil(process) <- delegate.process,
      {:ok, file} <- StepsPdf.create_pdf_file(delegate.process)
    ) do
      Mailer.build_email(
        "job_seeker/receive_synthesis.html",
        :avril,
        job_seeker,
        %{
          subject: "Votre synthèse VAE par Avril - la VAE facile",
          attachment:
            Swoosh.Attachment.new(file,
              filename: "synthese-vae.pdf",
              content_type: "application/pdf"
            ),
          footer_note: :mise_en_relation
        }
      )
    else
      _error ->
        Logger.warn("No process for delegate #{delegate.name}")
    end
  end

  def campaign(job_seeker) do
    Mailer.build_email(
      "job_seeker/campaign.html",
      :avril,
      job_seeker,
      %{
        subject:
          "Malgré les évènements, restons tournés vers l'avenir. Avec Avril obtenez un diplôme sans suivre de formation, c'est votre expérience qui compte.",
        url:
          Routes.root_url(
            Vae.Endpoint,
            :index,
            utm_campaign: "mj-#{Date.utc_today() |> to_string()}",
            utm_source: (job_seeker.geolocation["administrative"] || []) |> List.first(),
            utm_medium: "email",
            js_id: job_seeker.id
          ),
        image_url:
          Routes.static_url(
            Vae.Endpoint,
            "/images/mon-diplome.jpg"
          ),
        text_center: true,
        job_seeker_id: job_seeker.id,
        job_seeker_msg: true,
        footer_note: :inscrit_de,
        custom_id: UUID.uuid5(nil, job_seeker.email)
      }
    )
  end

  def stock(job_seeker) do
    Mailer.build_email(
      Vae.Crm.Config.get_stock_template_id(),
      :avril,
      job_seeker,
      %{
        job_seeker_id: job_seeker.id,
        footer_note: :mise_en_relation
      }
    )
  end
end
