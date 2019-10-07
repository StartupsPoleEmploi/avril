defmodule Vae.JobSeekerEmail do
  alias Vae.Mailer

  def receive_synthesis(job_seeker, process) when not is_nil(process) do
    with {:ok, file} <- Vae.StepsPdf.create_pdf_file(process) do
      Mailer.build_email(
        "job_seeker/receive_synthesis.html",
        :avril,
        job_seeker.email,
        %{
          subject: "Votre synthèse VAE par Avril - la VAE facile",
          attachment: Swoosh.Attachment.new(file, filename: "synthese-vae.pdf", content_type: "application/pdf")
        }
      )
    end
  end
end