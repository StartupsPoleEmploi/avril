defmodule Vae.PoleEmploi.Mappers.SkillsMapper do
  def map(%OAuth2.Response{body: body}) do
    %{
      skills: Enum.map(body, &to_skill/1)
    }
  end

  def is_data_missing(map), do: is_nil(map[:skills]) || Enum.empty?(map[:skills])

  defp to_skill(body) do
    %{
      code: String.to_integer(body["code"] || "0"),
      label: body["libelle"],
      type: body["type"],
      level_code: String.to_integer(body["niveau"]["code"] || "0"),
      level_label: body["niveau"]["libelle"]
    }
  end
end
