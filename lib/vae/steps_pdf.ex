defmodule Vae.StepsPdf do
  def create_pdf(process) do
    render_steps = Vae.ProcessView.render_steps(process, step_class: "")

    full = """
      <head>
        <link href="https://avril.pole-emploi.fr/css/app.css" rel="stylesheet">
        <link href="https://fonts.googleapis.com/css?family=Roboto|Lato|Nunito+Sans" rel="stylesheet">
      </head>
      <body>
        #{Enum.map_join(render_steps, &Phoenix.HTML.safe_to_string/1)}
      </body>
    """

    PdfGenerator.generate_binary(
      full,
      shell_params: ["--encoding", "UTF8"],
      delete_temporary: true
    )
  end
end
