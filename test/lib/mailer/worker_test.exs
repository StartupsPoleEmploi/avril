defmodule Vae.Mailer.WorkerTest do
  use ExUnit.Case

  test "update nothing" do
    params = [
      %{
        "CustomID" => "45",
        "MessageID" => 23,
        "Payload" => "bonjour, deoijoij",
        "customcampaign" => "123",
        "email" => "nresnikow@gmail.com",
        "event" => "open",
        "mj_campaign_id" => 1,
        "mj_contact_id" => 2323,
        "time" => "2018-07-08"
      },
      %{
        "CustomID" => "46",
        "MessageID" => 21,
        "Payload" => "bonjour, deoijoij",
        "customcampaign" => "123",
        "email" => "m.nicolas.zilli@gmail.com",
        "event" => "click",
        "mj_campaign_id" => 1,
        "mj_contact_id" => 2323,
        "time" => "2018-07-08"
      }
    ]

    assert [] == Vae.Mailer.Worker.update_emails_from_events([], params)
  end

  test "update emails with 0 event" do
    existing_emails_no_events = %Vae.Mailer.Email{
      events: [],
      custom_id: "45"
    }

    existing_events = %Vae.Event{
      custom_id: "46",
      message_id: 21,
      payload: "bonjour, deoijoij",
      customcampaign: "123",
      email: "m.nicolas.zilli@gmail.com",
      event: "open",
      campaign_id: 1,
      contact_id: 2323,
      time: "2018-07-06"
    }

    existing_emails_with_events = %Vae.Mailer.Email{
      events: [
        existing_events
      ],
      custom_id: "46"
    }

    emails = [existing_emails_no_events, existing_emails_with_events]

    assert emails === Vae.Mailer.Worker.update_emails_from_events(emails, [])
  end

  test "updates emails with more than one event" do
    params_45 = %{
      "CustomID" => "45",
      "MessageID" => 23,
      "Payload" => "bonjour, deoijoij",
      "customcampaign" => "123",
      "email" => "nresnikow@gmail.com",
      "event" => "open",
      "mj_campaign_id" => 1,
      "mj_contact_id" => 2323,
      "time" => "2018-07-08"
    }

    params_46 = %{
      "CustomID" => "46",
      "MessageID" => 21,
      "Payload" => "bonjour, deoijoij",
      "customcampaign" => "123",
      "email" => "m.nicolas.zilli@gmail.com",
      "event" => "click",
      "mj_campaign_id" => 1,
      "mj_contact_id" => 2323,
      "time" => "2018-07-08"
    }

    emails_45 = %Vae.Mailer.Email{
      events: [],
      custom_id: "45"
    }

    event_46 = %Vae.Event{
      custom_id: "46",
      message_id: 21,
      payload: "bonjour, deoijoij",
      customcampaign: "123",
      email: "m.nicolas.zilli@gmail.com",
      event: "open",
      campaign_id: 1,
      contact_id: 2323,
      time: "2018-07-06"
    }

    emails_46 = %Vae.Mailer.Email{
      events: [
        event_46
      ],
      custom_id: "46"
    }

    built_params_45 = Vae.Event.build_from_map(:email, params_45)
    updated_emails_45 = Map.put(emails_45, :events, [built_params_45 | emails_45.events])

    built_params_46 = Vae.Event.build_from_map(:email, params_46)
    updated_emails_46 = Map.put(emails_46, :events, [built_params_46 | emails_46.events])

    updated_emails =
      Vae.Mailer.Worker.update_emails_from_events([emails_45, emails_46], [params_45, params_46])

    assert [updated_emails_45, updated_emails_46] == updated_emails
  end
end
