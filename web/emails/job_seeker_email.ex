defmodule Vae.JobSeekerEmail do
  import Swoosh.Email
  use Phoenix.Swoosh,
    view: Vae.EmailView,
    layout: {Vae.LayoutView, :email}

  def receive_synthesis(job_seeker, process) when not is_nil(process) do
    with {:ok, file} <- Vae.StepsPdf.create_pdf_file(process) do
      new()
      |> from(Vae.Mailer.from_avril)
      |> to(job_seeker.email)
      |> subject("Votre synthèse VAE par Avril - la VAE facile")
      |> attachment(Swoosh.Attachment.new(file, filename: "synthese-vae.pdf", content_type: "application/pdf"))
      |> render_body("job_seeker/receive_synthesis.html", %{})
    end
  end
end