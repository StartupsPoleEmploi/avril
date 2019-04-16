defmodule Vae.StepsPdf do
  alias Vae.CertificationView

  def create_pdf(process) do
    process
    |> html()
    |> PdfGenerator.generate_binary(
      shell_params: ["--encoding", "UTF8"],
      delete_temporary: true
    )
  end

  def create_pdf_file(process) do
    process
    |> html()
    |> PdfGenerator.generate(shell_params: ["--encoding", "UTF8"])
  end

  def create_pdf_file!(process) do
    process
    |> html()
    |> PdfGenerator.generate!(shell_params: ["--encoding", "UTF8"])
  end

  defp html(process) do
    render_steps = CertificationView.render_steps(process, step_class: "")

    """
      <head>
        <link href="https://avril.pole-emploi.fr/css/app.css" rel="stylesheet">
        <link href="https://fonts.googleapis.com/css?family=Roboto|Lato|Nunito+Sans" rel="stylesheet">
      </head>
      <body>
        <img
          height="auto"
          src="http://yt18.mjt.lu/tplimg/yt18/b/6yv1/3t9t.png"
          class="img-fluid"
        />
        #{Enum.map_join(render_steps, &Phoenix.HTML.safe_to_string/1)}
      </body>
    """
  end
end
