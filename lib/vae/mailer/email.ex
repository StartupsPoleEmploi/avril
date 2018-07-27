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
    time: nil,
    email: nil,
    mj_campaign_id: nil,
    mj_contact_id: nil,
    customcampaign: nil,
    message_id: nil,
    custom_id: nil,
    payload: nil
  )

  def build_from_map(params) do
    %Vae.Mailer.Event{
      event: params["event"],
      time: params["time"],
      email: params["email"],
      mj_campaign_id: params["mj_campaign_id"],
      mj_contact_id: params["mj_contact_id"],
      customcampaign: params["customcampaign"],
      message_id: params["MessageID"],
      custom_id: params["CustomID"],
      payload: params["Payload"]
    }
  end

  def extract_custom_ids(events) do
    Enum.map(events, & &1.custom_id)
  end
end
