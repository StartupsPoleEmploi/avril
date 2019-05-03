defmodule Vae.Mailer.Email do
  defstruct(
    custom_id: nil,
    job_seeker: nil,
    state: :pending,
    template_id: nil,
    vars: %{},
    errors: []
  )

  def extract_custom_ids(emails) do
    Enum.map(emails, & &1.custom_id)
  end
end
