defmodule Vae.ApiTest do
  use Vae.DataCase

  alias Vae.{Event, JobSeeker}

  test "convert email event params to email event struct" do
    params = %{
      "CustomID" => "45",
      "MessageID" => "23",
      "Payload" => "bonjour, deoijoij",
      "customcampaign" => "123",
      "email" => "foo@bar.com",
      "event" => "open",
      "mj_campaign_id" => "1",
      "mj_contact_id" => "avril@pole-emploi.fr",
      "time" => "2018-07-08"
    }

    assert %Event{
             type: "email",
             custom_id: "45",
             customcampaign: "123",
             event: "open",
             message_id: "23",
             campaign_id: "1",
             contact_id: "avril@pole-emploi.fr",
             payload: "bonjour, deoijoij",
             time: "2018-07-08",
             email: "foo@bar.com"
           } == Event.build_from_map(:email, params)
  end

  test "handle empty event params" do
    job_seeker =
      %JobSeeker{
        email: "foo@bar.com"
      }
      |> Vae.Repo.insert!()

    assert [] == Event.Api.new_email_event() |> Event.Api.handle_email_event([])

    inserted_job_seeker = JobSeeker.retrieve_by_email("foo@bar.com")

    assert job_seeker == inserted_job_seeker
  end

  test "handle event params with a non existing job seeker, create it" do
    params = [
      %{
        "CustomID" => "45",
        "MessageID" => "23",
        "Payload" => "bonjour, deoijoij",
        "customcampaign" => "123",
        "email" => "foo@bar.com",
        "event" => "open",
        "mj_campaign_id" => "1",
        "mj_contact_id" => "avril@pole-emploi.fr",
        "time" => 1_433_333_949
      }
    ]

    expected_events = [
      %Vae.Event{
        campaign_id: "1",
        contact_id: "avril@pole-emploi.fr",
        custom_id: "45",
        customcampaign: "123",
        email: "foo@bar.com",
        event: "open",
        message_id: "23",
        payload: "bonjour, deoijoij",
        time: DateTime.from_unix!(1_433_333_949),
        type: "email"
      }
    ]

    created_job_seeker =
      Event.Api.new_email_event() |> Event.Api.handle_email_event(params) |> hd()

    assert created_job_seeker.email == "foo@bar.com"
    assert created_job_seeker.events == expected_events
  end

  test "handle multiple events on a non existing job seeker, create and update job seeker" do
    params = [
      %{
        "CustomID" => "45",
        "MessageID" => "23",
        "Payload" => "bonjour, deoijoij",
        "customcampaign" => "123",
        "email" => "foo@bar.com",
        "event" => "open",
        "mj_campaign_id" => "1",
        "mj_contact_id" => "avril@pole-emploi.fr",
        "time" => 1_433_333_949
      },
      %{
        "CustomID" => "45",
        "MessageID" => "23",
        "Payload" => "bonjour, deoijoij",
        "customcampaign" => "123",
        "email" => "foo@bar.com",
        "event" => "click",
        "mj_campaign_id" => "1",
        "mj_contact_id" => "avril@pole-emploi.fr",
        "time" => 1_533_374_065
      }
    ]

    updated_job_seekers = Event.Api.new_email_event() |> Event.Api.handle_email_event(params)

    expected_events = [
      %Vae.Event{
        campaign_id: "1",
        contact_id: "avril@pole-emploi.fr",
        custom_id: "45",
        customcampaign: "123",
        email: "foo@bar.com",
        event: "open",
        message_id: "23",
        payload: "bonjour, deoijoij",
        time: DateTime.from_unix!(1_433_333_949),
        type: "email"
      },
      %Vae.Event{
        campaign_id: "1",
        contact_id: "avril@pole-emploi.fr",
        custom_id: "45",
        customcampaign: "123",
        email: "foo@bar.com",
        event: "click",
        message_id: "23",
        payload: "bonjour, deoijoij",
        time: DateTime.from_unix!(1_533_374_065),
        type: "email"
      }
    ]

    updated_job_seeker = Vae.Repo.get_by(JobSeeker, email: "foo@bar.com")

    assert Enum.sort_by(updated_job_seeker.events, & &1.time) ==
             Enum.sort_by(expected_events, & &1.time)
  end

  test "handle event params on existing job seeker, update it" do
    job_seeker =
      %JobSeeker{
        email: "foo@bar.com"
      }
      |> Vae.Repo.insert!()

    params = [
      %{
        "CustomID" => "45",
        "MessageID" => "23",
        "Payload" => "bonjour, deoijoij",
        "customcampaign" => "123",
        "email" => "foo@bar.com",
        "event" => "open",
        "mj_campaign_id" => "1",
        "mj_contact_id" => "avril@pole-emploi.fr",
        "time" => 1_433_333_949
      }
    ]

    updated_job_seekers = Event.Api.new_email_event() |> Event.Api.handle_email_event(params)

    expected_events = [
      %Vae.Event{
        campaign_id: "1",
        contact_id: "avril@pole-emploi.fr",
        custom_id: "45",
        customcampaign: "123",
        email: "foo@bar.com",
        event: "open",
        message_id: "23",
        payload: "bonjour, deoijoij",
        time: DateTime.from_unix!(1_433_333_949),
        type: "email"
      }
    ]

    assert length(updated_job_seekers) == 1
    assert hd(updated_job_seekers).events == expected_events
  end

  test "handle multpile event params, update job_seeker" do
    job_seeker =
      %JobSeeker{
        email: "foo@bar.com"
      }
      |> Vae.Repo.insert!()

    params = [
      %{
        "CustomID" => "45",
        "MessageID" => "23",
        "Payload" => "bonjour, deoijoij",
        "customcampaign" => "123",
        "email" => "foo@bar.com",
        "event" => "open",
        "mj_campaign_id" => "1",
        "mj_contact_id" => "avril@pole-emploi.fr",
        "time" => 1_433_333_949
      },
      %{
        "CustomID" => "45",
        "MessageID" => "23",
        "Payload" => "bonjour, deoijoij",
        "customcampaign" => "123",
        "email" => "foo@bar.com",
        "event" => "click",
        "mj_campaign_id" => "1",
        "mj_contact_id" => "avril@pole-emploi.fr",
        "time" => 1_533_374_065
      }
    ]

    updated_job_seekers = Event.Api.new_email_event() |> Event.Api.handle_email_event(params)

    expected_events = [
      %Vae.Event{
        campaign_id: "1",
        contact_id: "avril@pole-emploi.fr",
        custom_id: "45",
        customcampaign: "123",
        email: "foo@bar.com",
        event: "open",
        message_id: "23",
        payload: "bonjour, deoijoij",
        time: DateTime.from_unix!(1_433_333_949),
        type: "email"
      },
      %Vae.Event{
        campaign_id: "1",
        contact_id: "avril@pole-emploi.fr",
        custom_id: "45",
        customcampaign: "123",
        email: "foo@bar.com",
        event: "click",
        message_id: "23",
        payload: "bonjour, deoijoij",
        time: DateTime.from_unix!(1_533_374_065),
        type: "email"
      }
    ]

    updated_job_seeker = Vae.Repo.get(JobSeeker, job_seeker.id)

    assert Enum.sort_by(updated_job_seeker.events, & &1.time) ==
             Enum.sort_by(expected_events, & &1.time)
  end
end
