defmodule Vae.Authentication.Client do
  defstruct client: OAuth2.Client.new([]),
            state: nil,
            nonce: nil,
            access_token: nil
end
