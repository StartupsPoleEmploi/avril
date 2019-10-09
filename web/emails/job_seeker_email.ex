defmodule Vae.JobSeekerEmail do
  alias Vae.Mailer
  alias Vae.Router.Helpers, as: Routes

  def receive_synthesis(job_seeker, process) when not is_nil(process) do
    with {:ok, file} <- Vae.StepsPdf.create_pdf_file(process) do
      Mailer.build_email(
        "job_seeker/receive_synthesis.html",
        :avril,
        job_seeker,
        %{
          subject: "Votre synthèse VAE par Avril - la VAE facile",
          attachment: Swoosh.Attachment.new(file, filename: "synthese-vae.pdf", content_type: "application/pdf")
        }
      )
    end
  end

  def campaign(job_seeker) do
    Mailer.build_email(
      "job_seeker/campaign.html",
      :avril,
      job_seeker,
      %{
        subject: "Votre conseiller pôle emploi vous invite à tester un nouveau site : Avril, la VAE facile !",
        url: Routes.root_url(
          Vae.Endpoint,
          :index,
          utm_campaign: "mj-#{Date.utc_today() |> to_string()}",
          utm_source: (job_seeker.geolocation["administrative"] || []) |> List.first(),
          utm_medium: "email",
          js_id: job_seeker.id
        ),
        image_url: "#{Vae.Endpoint.static_url()}#{Vae.Endpoint.static_path("/images/mon-diplome.jpg")}",
        text_center: true,
        job_seeker_id: job_seeker.id,
        job_seeker_msg: true
      }
    )
  end
end
