defmodule Vae.PoleEmploi.Mappers.CivilStatusMapper do
  def map(%OAuth2.Response{body: body}) do
    %{
      birthday: Timex.parse!(body["dateDeNaissance"], "{ISO:Extended}")
    }
  end

  def is_missing?(map), do: is_nil(map[:identity])
end
