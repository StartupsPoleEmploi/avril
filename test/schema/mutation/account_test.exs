defmodule VaeWeb.Schema.Mutation.AccountTest do
  use VaeWeb.ConnCase, async: true

  setup %{conn: conn} do
    ExMachina.Sequence.reset()

    user =
      build(:user, %{
        gender: "M",
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
      |> set_password("1234567890")
      |> insert

    authed_conn = Pow.Plug.assign_current_user(conn, user, otp_app: :vae)

    {:ok, conn: authed_conn}
  end

  @query """
  mutation UpdateProfile($profileItem: ProfileInput){
    profile: updateProfile(input: $profileItem) {
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
  test "update user's profile", %{conn: conn} do
    profile_item = %{
      "gender" => "F",
      "birthday" => "1960-05-31",
      "birthPlace" => %{
        "city" => "Berlin"
      },
      "firstName" => "Jane",
      "lastName" => "Doe",
      "email" => "jane@doe.com",
      "phoneNumber" => "0102030405",
      "fullAddress" => %{
        "street" => "3868  Stuart Street",
        "postalCode" => "15222",
        "city" => "Pittsburgh",
        "country" => "US"
      }
    }

    conn = post conn, "/api/v2", query: @query, variables: %{"profileItem" => profile_item}

    assert json_response(conn, 200) == %{
             "data" => %{
               "profile" => %{
                 "gender" => profile_item["gender"],
                 "birthday" => profile_item["birthday"],
                 "birthPlace" => %{
                   "city" => profile_item["birthPlace"]["city"]
                 },
                 "firstName" => profile_item["firstName"],
                 "lastName" => profile_item["lastName"],
                 "email" => profile_item["email"],
                 "phoneNumber" => profile_item["phoneNumber"],
                 "fullAddress" => %{
                   "street" => profile_item["fullAddress"]["street"],
                   "postalCode" => profile_item["fullAddress"]["postalCode"],
                   "city" => profile_item["fullAddress"]["city"],
                   "country" => profile_item["fullAddress"]["country"]
                 }
               }
             }
           }
  end

  @query """
  mutation UpdatePassword ($passwordItem: PasswordInput!) {
    updatePassword(input: $passwordItem) {
      firstName
    }
  }
  """
  test "Updating a password with a wrong current password fails", %{conn: conn} do
    password_item = %{
      current_password: "foo",
      password: "new_password",
      confirm_password: "new_password"
    }

    conn = post conn, "/api/v2", query: @query, variables: %{"passwordItem" => password_item}

    assert json_response(conn, 200) ==
             %{
               "errors" => [
                 %{
                   "locations" => [%{"column" => 0, "line" => 2}],
                   "message" => "Erreur lors de la mise à jour du mot de passe",
                   "details" => [%{"key" => "current_password", "message" => ["is invalid"]}],
                   "path" => ["updatePassword"]
                 }
               ],
               "data" => %{"updatePassword" => nil}
             }
  end

  @query """
  mutation UpdatePassword ($passwordItem: PasswordInput!) {
    updatePassword(input: $passwordItem) {
      firstName
    }
  }
  """
  test "Updating a password when new password and password confirmation do not match fails", %{
    conn: conn
  } do
    password_item = %{
      current_password: "foo",
      password: "new_password",
      confirm_password: "password"
    }

    conn = post(conn, "/api/v2", query: @query, variables: %{"passwordItem" => password_item})

    assert json_response(conn, 200) ==
             %{
               "data" => %{"updatePassword" => nil},
               "errors" => [
                 %{
                   "details" => [
                     %{
                       "key" => "password_confirmation",
                       "message" => ["does not match confirmation"]
                     }
                   ],
                   "locations" => [%{"column" => 0, "line" => 2}],
                   "message" => "Erreur lors de la mise à jour du mot de passe",
                   "path" => ["updatePassword"]
                 }
               ]
             }
  end

  @query """
  mutation UpdatePassword ($passwordItem: PasswordInput!) {
    updatePassword(input: $passwordItem) {
      firstName
    }
  }
  """
  test "Updating a password", %{conn: conn} do
    password_item = %{
      current_password: "1234567890",
      password: "new_password",
      confirm_password: "new_password"
    }

    conn = post conn, "/api/v2", query: @query, variables: %{"passwordItem" => password_item}

    assert json_response(conn, 200) == %{
             "data" => %{"updatePassword" => %{"firstName" => "John"}}
           }
  end
end
