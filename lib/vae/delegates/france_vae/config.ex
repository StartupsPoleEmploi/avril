defmodule Vae.Delegates.FranceVae.Config do
  def get_oauth_url() do
    System.get_env("FRANCE_VAE_OAUTH_URL")
  end

  def get_base_url() do
    System.get_env("FRANCE_VAE_BASE_URL")
  end

  def get_client_id() do
    System.get_env("FRANCE_VAE_CLIENT_ID")
  end

  def get_client_secret() do
    System.get_env("FRANCE_VAE_CLIENT_SECRET")
  end
end
