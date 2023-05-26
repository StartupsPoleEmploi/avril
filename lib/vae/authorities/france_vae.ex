defmodule Vae.Authorities.FranceVae do

  def is_reva?() do
    Timex.before?(Timex.today(), Application.get_env(:vae, :deadlines)[:reva_end])
  end

  def is_france_vae?() do
    Timex.before?(Application.get_env(:vae, :deadlines)[:fvae_start], Timex.today())
  end
end
