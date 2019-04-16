defmodule Vae.Authentication do
  @authentication_config Application.get_env(:vae, :authentication)

  def init_client() do
    OAuth2.Client.new(
      [
        params: %{
          realm: "/individu",
          scope:
            "application_#{Keyword.get(@authentication_config, :client_id)} api_peconnect-individuv1 openid profile email api_peconnect-formationsv1 pfcformations api_peconnect-experiencesprofessionellesdeclareesparlemployeurv1 passeprofessionnel api_peconnect-experiencesv1 pfcexperiences api_peconnect-coordonneesv1 coordonnees api_peconnect-competencesv2 pfccompetences pfclangues pfccentresinteret",
          state: UUID.uuid4(:hex),
          nonce: UUID.uuid4(:hex)
        },
        request_opts: [recv_timeout: 3000]
      ] ++ @authentication_config
    )
  end

  def get_authorize_url!(client) do
    OAuth2.Client.authorize_url!(client)
  end

  def generate_access_token(
        %OAuth2.Client{client_secret: client_secret} = client,
        code
      ) do
    %{
      client
      | token_url: "/connexion/oauth2/access_token?realm=/individu",
        params: %{
          client_secret: client_secret
        }
    }
    |> OAuth2.Client.get_token!(code: code)
  end

  def get(client, resource_url) do
    OAuth2.Client.get!(client, resource_url)
  end
end
