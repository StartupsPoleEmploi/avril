defmodule Vae.Meetings.FranceVae.Connection do
  defstruct delegate: nil,
            access_token: nil,
            refresh_token: nil,
            init_at: DateTime.utc_now(),
            expires_in: nil
end
