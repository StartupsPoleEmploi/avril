defmodule VaeWeb.AdminEmail do
  alias VaeWeb.Mailer

  def stats(file) do
    Mailer.build_email(
      "admin/stats.html",
      :avril,
      :avril,
      %{
        attachment:
          Swoosh.Attachment.new(file,
            filename: Path.basename(file),
            content_type: "text/csv"
          )
      }
    )
  end
end
