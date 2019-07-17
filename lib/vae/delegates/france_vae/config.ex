defmodule Vae.Delegates.FranceVae.Config do
  def get_domain_name() do
    System.get_env("FRANCE_VAE_DOMAIN_NAME")
  end

  def get_oauth_url() do
    "#{get_domain_name()}#{System.get_env("FRANCE_VAE_OAUTH_PATH")}"
  end

  def get_base_url() do
    "#{get_domain_name()}#{System.get_env("FRANCE_VAE_BASE_PATH")}"
  end

  def get_client_id() do
    System.get_env("FRANCE_VAE_CLIENT_ID")
  end

  def get_client_secret() do
    System.get_env("FRANCE_VAE_CLIENT_SECRET")
  end

  def get_france_vae_academy_page(academy_id) when is_nil(academy_id) or academy_id == "" do
    nil
  end

  def get_france_vae_academy_page(academy_id) do
    "#{get_domain_name()}/academie/#{academy_id}"
  end

  def get_france_vae_form_url(academy_id) when is_nil(academy_id) or academy_id == "" do
    nil
  end

  def get_france_vae_form_url(academy_id) do
    "#{get_domain_name()}/academie/demande-information/#{academy_id}"
  end

  def get_france_vae_form_url(academy_id, meeting_id) when is_nil(meeting_id) or meeting_id == "" do
    get_france_vae_form_url(academy_id)
  end
  # def get_france_vae_form_url(academy_id, "") do: get_france_vae_form_url(academy_id)
  def get_france_vae_form_url(academy_id, meeting_id) do
    "#{get_domain_name()}/academie/inscription-rdv/#{academy_id}/#{meeting_id}"
  end
end
