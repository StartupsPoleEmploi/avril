defmodule Vae.Mailer.Email do
  defstruct(
    custom_id: nil,
    job_seeker: nil,
    email_state: nil,
    events: [],
    errors: []
  )

  def extract_custom_ids(emails) do
    Enum.map(emails, & &1.custom_id)
  end
end

defmodule Vae.Mailer.Event do
  defstruct(
    event: nil,
    received_at: nil
  )
end
