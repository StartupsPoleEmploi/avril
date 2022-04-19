defmodule Vae.PoleEmploi.Mappers.UserInfoMapper do
  alias Vae.Repo

  def map(%OAuth2.Response{body: body}) do
    %{
      gender: body["gender"],
      email: String.downcase(body["email"]),
      first_name: Vae.String.capitalize(body["given_name"]),
      last_name: Vae.String.capitalize(body["family_name"]),
      pe_id: body["idIdentiteExterne"],
      email_confirmed_at: Timex.now()
    }
  end

  def is_missing?(map), do: is_nil(map[:identity])
end
