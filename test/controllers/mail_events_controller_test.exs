defmodule VaeWeb.MailEventsControllerTest do
  use VaeWeb.ConnCase

  test "new_event/2 updates job_seeker events" do
    conn = build_conn()

    params = %{
      _json: [
        %{
          "CustomID" => "45",
          "MessageID" => 23,
          "Payload" => "bonjour, deoijoij",
          "agent" => "",
          "customcampaign" => "123",
          "email" => "foo@bar.com",
          "event" => "open",
          "geo" => "",
          "ip" => "",
          "mj_campaign_id" => 1,
          "mj_contact_id" => 2323,
          "time" => 1_533_378_969
        }
      ]
    }

    expected_events = [
      %Vae.Event{
        campaign_id: 1,
        contact_id: 2323,
        custom_id: "45",
        customcampaign: "123",
        email: "foo@bar.com",
        event: "open",
        message_id: 23,
        payload: "bonjour, deoijoij",
        time: DateTime.from_unix!(1_533_378_969),
        type: "email"
      }
    ]

    post(conn, "/mail_events", params)

    job_seeker = Vae.Repo.get_by!(Vae.JobSeeker, email: "foo@bar.com")
    assert job_seeker.events == expected_events
  end

  test "new_event/2 updates job_seeker events with mutli events" do
    conn = build_conn()

    params = %{
      _json: [
        %{
          "CustomID" => "45",
          "MessageID" => 23,
          "Payload" => "bonjour, deoijoij",
          "agent" => "",
          "customcampaign" => "123",
          "email" => "foo@bar.com",
          "event" => "open",
          "geo" => "",
          "ip" => "",
          "mj_campaign_id" => 1,
          "mj_contact_id" => 2323,
          "time" => 1_433_333_949
        },
        %{
          "CustomID" => "45",
          "MessageID" => 23,
          "Payload" => "bonjour, deoijoij",
          "agent" => "",
          "customcampaign" => "123",
          "email" => "foo@bar.com",
          "event" => "click",
          "geo" => "",
          "ip" => "",
          "mj_campaign_id" => 1,
          "mj_contact_id" => 2323,
          "time" => 1_533_378_969
        }
      ]
    }

    expected_events = [
      %Vae.Event{
        campaign_id: 1,
        contact_id: 2323,
        custom_id: "45",
        customcampaign: "123",
        email: "foo@bar.com",
        event: "open",
        message_id: 23,
        payload: "bonjour, deoijoij",
        time: DateTime.from_unix!(1_433_333_949),
        type: "email"
      },
      %Vae.Event{
        campaign_id: 1,
        contact_id: 2323,
        custom_id: "45",
        customcampaign: "123",
        email: "foo@bar.com",
        event: "click",
        message_id: 23,
        payload: "bonjour, deoijoij",
        time: DateTime.from_unix!(1_533_378_969),
        type: "email"
      }
    ]

    post(conn, "/mail_events", params)

    job_seeker = Vae.Repo.get_by!(Vae.JobSeeker, email: "foo@bar.com")
    assert Enum.sort_by(job_seeker.events, & &1.time) == Enum.sort_by(expected_events, & &1.time)
  end
end
