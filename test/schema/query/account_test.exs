defmodule VaeWeb.Schema.Query.AccountTest do
  use VaeWeb.ConnCase, async: true

  setup %{conn: conn} do
    ExMachina.Sequence.reset()

    user =
      insert(:user, %{
        gender: "female",
        birthday: ~D[1981-06-24],
        birth_place: "Paris",
        first_name: "John",
        last_name: "Smith",
        email: "john@smith.com",
        phone_number: "0000000000",
        city_label: "Beaune",
        country_label: "France",
        postal_code: "21200",
        address1: "13 rue de la pie qui chante",
        address2: "Rue de droite",
        address3: "Face à la mer",
        address4: "Derrière l'arbre"
      })

    authed_conn = Pow.Plug.assign_current_user(conn, user, otp_app: :vae)

    {:ok, conn: authed_conn}
  end

  @query """
  {
    profile {
      gender
      birthday
      birthPlace {
        city
      }
      firstName
      lastName
      email
      phoneNumber
      fullAddress {
        street
        postalCode
        city
        country
      }
    }
  }
  """
  test "the profile fields returns the current user's profile", %{conn: conn} do
    conn = get conn, "/api/v2", query: @query

    assert json_response(conn, 200) == %{
             "data" => %{
               "profile" => %{
                 "birthPlace" => %{
                   "city" => "Paris"
                 },
                 "birthday" => "1981-06-24",
                 "email" => "john@smith.com",
                 "firstName" => "John",
                 "fullAddress" => %{
                   "city" => "Beaune",
                   "country" => "France",
                   "postalCode" => "21200",
                   "street" =>
                     "13 rue de la pie qui chante, Rue de droite, Face à la mer, Derrière l'arbre"
                 },
                 "gender" => "female",
                 "lastName" => "Smith",
                 "phoneNumber" => "0000000000"
               }
             }
           }
  end
end
