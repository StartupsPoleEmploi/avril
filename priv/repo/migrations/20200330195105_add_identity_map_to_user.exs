defmodule Vae.Repo.Migrations.AddIdentityMapToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:identity, :map)
    end

    flush()

    Vae.Repo.all(Vae.User)
    |> Vae.Repo.preload(:applications)
    |> Enum.map(fn u ->
      user_identity =
        u.applications
        |> Enum.sort(&(NaiveDateTime.compare(&1.updated_at, &2.updated_at) != :lt))
        |> Enum.find(fn application ->
          application.booklet_1 != nil
        end)
        |> case do
          nil ->
            identity_map(u)

          a ->
            Map.merge(
              identity_map(u),
              Map.from_struct(get_in(a, [Access.key(:booklet_1), Access.key(:civility)])),
              &deep/3
            )
        end

      Vae.Account.update_identity(%{identity: user_identity}, u)
    end)
  end

  defp identity_map(u) do
    %{
      gender: u.gender,
      birthday: u.birthday,
      first_name: u.first_name,
      last_name: u.last_name,
      usage_name: nil,
      email: u.email,
      home_phone: nil,
      mobile_phone: u.phone_number,
      is_handicapped: false,
      birth_place: %{
        city: u.birth_place,
        county: nil
      },
      full_address: %{
        city: u.city_label,
        county: nil,
        country: u.country_label,
        lat: nil,
        lng: nil,
        street: Vae.Account.address_street(u),
        postal_code: u.postal_code
      },
      current_situation: %{},
      nationality: %{
        country: nil,
        country_code: nil
      }
    }
  end

  defp deep(_k, nil, nil), do: nil

  defp deep(_k, nil, v2) when is_binary(v2), do: v2

  defp deep(_k, v1, nil) when is_binary(v1), do: v1

  defp deep(_k, nil, %Date{} = v2), do: v2

  defp deep(_k, %Date{} = v1, nil), do: v1

  defp deep(_k, %Date{} = v1, %Date{} = v2), do: v2

  defp deep(_k, m1, m2) when is_map(m2) and m1 in [nil, %{}], do: Map.from_struct(m2)

  defp deep(_k, m1, m2) when is_map(m1) and m2 in [nil, %{}], do: m1

  defp deep(k, m1, m2) when is_map(m1) do
    Map.merge(m1, Map.from_struct(m2), &deep/3)
  end

  defp deep(_k, _v1, v2), do: v2
end
