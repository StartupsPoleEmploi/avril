defmodule Vae.Delegates.FranceVae.UserRegistration do
  defstruct gender: nil,
            first_name: nil,
            last_name: nil,
            birthday_date: nil,
            birth_place: nil,
            address: nil,
            address_2: nil,
            postal_code: nil,
            city: nil,
            email: nil

  def from_user(user = %Vae.User{}) do
    %__MODULE__{
      gender: nil,
      first_name: user.first_name,
      last_name: user.last_name,
      birthday_date: nil,
      birth_place: nil,
      address: user.address1,
      address_2: List.join([user.address2, user.address3, user.address4], ", "),
      postal_code: user.postal_code,
      city: user.city_label,
      email: user.email
    }
  end

  def format(user_registration = %__MODULE__{}) do
    %{
      "civilite" => format_gender(user_registration[:gender]),
      "nom" => user_registration[:first_name],
      "nomNaiss" => user_registration[:first_name],
      "prenom" => user_registration[:last_name],
      "dateNaissance" => format_date(user_registration[:birth_date]),
      "lieuNaissance" => user_registration[:birth_place],
      "adresse" => user_registration[:address],
      "adresseBis" => user_registration[:address_2],
      "cp" => user_registration[:postal_code],
      "commune" => user_registration[:city],
      "courriel" => user_registration[:email]
    }
  end

  defp format_gender(gender) do
    case gender do
      "homme" -> 1
      _ -> 2
    end
  end

  defp format_date(date = %Date{}) do
    "24/06/1981"
  end
end
