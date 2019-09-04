defmodule Vae.Delegates.FranceVae.UserRegistration do
  @derive Jason.Encoder
  defstruct civilite: nil,
            nom: nil,
            nomNaiss: nil,
            prenom: nil,
            dateNaissance: nil,
            lieuNaissance: nil,
            adresse: nil,
            adresseBis: nil,
            cp: nil,
            commune: nil,
            courrier: nil,
            telephonePortable: nil,
            # Avril
            origine: 19,
            # Chosen diplome
            diplome: 1,
            diplomeVise: nil,
            # 1 => Réunion, 2 => Demande d'infos
            type: 2,
            # meeting_id
            reunion: nil

  def from_application(application = %Vae.Application{}) do
    user = application.user

    Map.merge(
      %__MODULE__{
        civilite: format_gender(user.gender),
        nom: user.last_name,
        nomNaiss: nil,
        prenom: user.first_name,
        dateNaissance: format_birthday(user.birthday),
        lieuNaissance: nil,
        cp: user.postal_code,
        commune: user.city_label,
        courrier: user.email,
        telephonePortable: format_phone_number(user.phone_number),
        diplomeVise: format_diplome_vise(application.certification.acronym)
      },
      format_address(user)
    )
  end

  def new_meeting_registration(application, meeting_id) do
    application
    |> from_application()
    |> Map.merge(%{
      reunion: meeting_id,
      type: 1
    })
  end

  defp format_birthday(birthday, for \\ :form)
  defp format_birthday(nil, _for), do: nil
  defp format_birthday(birthday, _for), do: Timex.format!(birthday, "%d/%m/%Y", :strftime)

  defp format_address(user) do
    Enum.reduce(
      [user.address1, user.address2, user.address3, user.address4],
      %{adresse: nil, adresseBis: nil},
      fn
        address_part, %{adresse: nil, adresseBis: part2} ->
          %{adresse: address_part, adresseBis: part2}

        address_part, %{adresse: part1, adresseBis: nil} ->
          %{adresse: part1, adresseBis: address_part}

        address_part, %{adresse: part1, adresseBis: part2} ->
          %{adresse: part1, adresseBis: Enum.join([part2, address_part], ", ")}
      end
    )
  end

  defp format_gender(gender) do
    case gender do
      "male" -> 1
      "female" -> 2
      _other -> nil
    end
  end

  defp format_phone_number(nil), do: nil

  defp format_phone_number(phone_number) do
    String.replace(phone_number, ~r/(\s|\.)+/, "")
  end

  defp format_diplome_vise("BEP"), do: 21
  defp format_diplome_vise("BAC PRO"), do: 14
  defp format_diplome_vise("CAP"), do: 43
  defp format_diplome_vise("BP"), do: 29
  defp format_diplome_vise("BTS"), do: 39
  defp format_diplome_vise("BMA"), do: 27
  defp format_diplome_vise("MC4"), do: 105
  defp format_diplome_vise("MC5"), do: 106
  defp format_diplome_vise(_), do: nil
  # Unmatching from Avril
  # "BE"
  # "BP"
  # "BT"
  # "CAPA"
  # "DCG"
  # "DE"
  # "DSCG"
  # Unmatching from France VAE
  # 49 - CERTIF E.N
  # 66 - DECESF
  # 79 - DIV-3
  # 80 - DIV-4
  # 81 - DIV-5
  # 82 - DMA
  # 12 - TITRES E.N
end
