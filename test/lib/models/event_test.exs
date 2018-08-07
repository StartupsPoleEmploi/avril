defmodule Vae.EventTest do
  use ExUnit.Case

  test "build event struct from params" do
    params = %{
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

    assert %Vae.Event{
             custom_id: "45",
             customcampaign: "123",
             email: "nresnikow@gmail.com",
             event: "open",
             message_id: 23,
             campaign_id: 1,
             contact_id: 2323,
             payload: "bonjour, deoijoij",
             time: "2018-07-08",
             type: "email"
           } == Vae.Event.build_from_map(:email, params)
  end
end
