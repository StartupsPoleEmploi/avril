defmodule Vae.Mailer.Email do
  defstruct(
    custom_id: nil,
    job_seeker: nil,
    email_state: nil,
    events: []
  )
end

defmodule Vae.Mailer.Event do
  defstruct(
    event: nil,
    received_at: nil
  )
end
