defmodule Vae.StepsPdf do
  def create_pdf(process) do
    render_steps = Vae.ProcessView.render_steps(process, step_class: "")

    full = """
      <head>
        <link href="http://localhost:4000/css/app.css" rel="stylesheet">
        <link href="https://fonts.googleapis.com/css?family=Roboto|Lato|Nunito+Sans" rel="stylesheet">
      </head>
      <body>
        #{Enum.map_join(render_steps, &Phoenix.HTML.safe_to_string/1)}
      </body>
    """

    PdfGenerator.generate_binary(
      full,
      page_size: "A4",
      shell_params: ["--encoding", "UTF8"]
    )
  end
end
