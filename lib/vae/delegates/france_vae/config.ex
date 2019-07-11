defmodule Vae.Delegates.FranceVae.Config do
  def get_domain_name() do
    System.get_env("FRANCE_VAE_DOMAIN_NAME")
  end

  def get_oauth_url() do
    "#{__MODULE__.get_domain_name()}#{System.get_env("FRANCE_VAE_OAUTH_PATH")}"
  end

  def get_base_url() do
    "#{__MODULE__.get_domain_name()}#{System.get_env("FRANCE_VAE_BASE_PATH")}"
  end

  def get_client_id() do
    System.get_env("FRANCE_VAE_CLIENT_ID")
  end

  def get_client_secret() do
    System.get_env("FRANCE_VAE_CLIENT_SECRET")
  end

  def get_meeting_form_url(academy_id, meeting_id) do
    "#{__MODULE__.get_domain_name}/academie/inscription-rdv/#{academy_id}/#{meeting_id}"
  end
end
