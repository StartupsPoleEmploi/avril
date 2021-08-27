defmodule Vae.Meetings.FranceVae.UserRegistration do
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
            origine: 100,
            # Chosen diplome
            diplome: 1,
            diplomeVise: nil,
            # 1 => Réunion, 2 => Demande d'infos
            type: 2,
            # meeting_id
            reunion: nil,
            commentaire: nil

  def from_application(application = %Vae.UserApplication{}) do
    identity = Vae.Maybe.try(application, [:user, :identity])

    %__MODULE__{
      civilite: format_gender(identity.gender),
      nom: identity.last_name,
      nomNaiss: nil,
      prenom: identity.first_name,
      dateNaissance: format_birthday(identity.birthday),
      lieuNaissance: "#{Vae.Maybe.try(identity, [:birth_place, :city])}, #{Vae.Maybe.try(identity, [:birth_place, :country])}",
      adresse: Vae.Maybe.try(identity, [:full_address, :street]),
      adresseBis: nil,
      cp: Vae.Maybe.try(identity, [:full_address, :postal_code]),
      commune: Vae.Maybe.try(identity, [:full_address, :city]),
      courrier: identity.email,
      telephonePortable: format_phone_number(identity.mobile_phone),
      diplomeVise: format_diplome_vise(application.certification.acronym),
      commentaire: Vae.Certification.name(application.certification)
    }
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

  defp format_gender(gender) do
    case String.first(gender) do
      "m" -> 1
      "f" -> 2
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
