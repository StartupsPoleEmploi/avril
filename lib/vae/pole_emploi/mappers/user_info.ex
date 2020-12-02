defmodule Vae.PoleEmploi.Mappers.UserInfoMapper do
  alias Vae.{JobSeeker, Repo}

  def map(%OAuth2.Response{body: body}) do
    %{
      gender: body["gender"],
      email: String.downcase(body["email"]),
      first_name: Vae.String.capitalize(body["given_name"]),
      last_name: Vae.String.capitalize(body["family_name"]),
      pe_id: body["idIdentiteExterne"],
      job_seeker:
        Repo.get_by(JobSeeker,
          email: String.downcase(body["email"])
        ),
      email_confirmed_at: Timex.now()
    }
  end

  def is_missing?(map), do: is_nil(map[:identity])
end
