defmodule Vae.PoleEmploi.Mappers.ContactMapper do
  def map(%OAuth2.Response{body: body}) do
    %{
      postal_code: body["codePostal"],
      address1: Vae.String.titleize(body["adresse1"]),
      address2: Vae.String.titleize(body["adresse2"]),
      address3: Vae.String.titleize(body["adresse3"]),
      address4: Vae.String.titleize(body["adresse4"]),
      insee_code: body["codeINSEE"],
      country_code: body["codePays"],
      city_label: Vae.String.titleize(body["libelleCommune"]),
      country_label: Vae.String.titleize(body["libellePays"])
    }
  end

  def is_missing?(map), do: is_nil(map[:postal_code])
end
