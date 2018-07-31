defmodule Vae.Mailer.EventTest do
  use ExUnit.Case

  test "build event struct from params" do
    params = %{
      "CustomID" => "45",
      "MessageID" => "23",
      "Payload" => "bonjour, deoijoij",
      "customcampaign" => "123",
      "email" => "nresnikow@gmail.com",
      "event" => "open",
      "mj_campaign_id" => "1",
      "mj_contact_id" => "avril@pole-emploi.fr",
      "time" => "2018-07-08"
    }

    assert %Vae.Mailer.Event{
             custom_id: "45",
             customcampaign: "123",
             email: "nresnikow@gmail.com",
             event: "open",
             message_id: "23",
             mj_campaign_id: "1",
             mj_contact_id: "avril@pole-emploi.fr",
             payload: "bonjour, deoijoij",
             time: "2018-07-08"
           } == Vae.Mailer.Event.build_from_map(params)
  end
end
