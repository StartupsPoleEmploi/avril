defmodule VaeWeb.Schema.Mutation.AccountTest do
  use VaeWeb.ConnCase, async: true

  setup %{conn: conn} do
    ExMachina.Sequence.reset()

    user =
      build(:user_with_identity)
      |> set_password("1234567890")
      |> insert

    authed_conn = Pow.Plug.assign_current_user(conn, user, otp_app: :vae)

    {:ok, conn: authed_conn}
  end

  @query """
  mutation UpdateIdentity($input: IdentityInput){
    identity: updateIdentity(input: $input) {
      gender
      birthday
      firstName
      lastName
      usageName
      email
      homePhone
      mobilePhone
      isHandicapped
      birthPlace {
        city
        county
        country
        lat
        lng
        street
        postalCode
      }
      fullAddress {
        city
        county
        country
        lat
        lng
        street
        postalCode
      }
      currentSituation {
        status
        employmentType
        registerToPoleEmploi
        registerToPoleEmploiSince
        compensationType
      }
      nationality {
        country
        countryCode
      }
    }
  }
  """
  test "update the identity of a user's profile", %{conn: conn} do
    identity_item = %{
      "gender" => "F",
      "birthday" => "1960-05-31",
      "firstName" => "Jane",
      "lastName" => "Doe",
      "usageName" => "Josh",
      "email" => "jane@doe.com",
      "homePhone" => "0102030405",
      "mobilePhone" => "0102030405",
      "isHandicapped" => true,
      "birthPlace" => %{
        "city" => "Berlin"
      },
      "fullAddress" => %{
        "city" => "Pittsburgh",
        "postalCode" => "15222",
        "country" => "US",
        "street" => "3868  Stuart Street",
        "lat" => 68.929735,
        "lng" => -29.977452
      },
      "currentSituation" => %{
        "status" => "worker",
        "employmentType" => "full-time",
        "registerToPoleEmploi" => false,
        "registerToPoleEmploiSince" => nil,
        "compensationType" => nil
      },
      "nationality" => %{
        "country" => "Etats-Unis",
        "country_code" => "US"
      }
    }

    conn = post conn, "/api/v2", query: @query, variables: %{"input" => identity_item}

    assert json_response(conn, 200) ==
             %{
               "data" => %{
                 "identity" => %{
                   "birthPlace" => %{
                     "city" => "Berlin",
                     "country" => nil,
                     "county" => nil,
                     "lat" => nil,
                     "lng" => nil,
                     "postalCode" => nil,
                     "street" => nil
                   },
                   "birthday" => "1960-05-31",
                   "currentSituation" => %{
                     "compensationType" => nil,
                     "employmentType" => "full-time",
                     "registerToPoleEmploi" => false,
                     "registerToPoleEmploiSince" => nil,
                     "status" => "worker"
                   },
                   "email" => "jane@doe.com",
                   "firstName" => "Jane",
                   "fullAddress" => %{
                     "city" => "Pittsburgh",
                     "country" => "US",
                     "county" => nil,
                     "lat" => 68.929735,
                     "lng" => -29.977452,
                     "postalCode" => "15222",
                     "street" => "3868  Stuart Street"
                   },
                   "gender" => "F",
                   "homePhone" => "0102030405",
                   "isHandicapped" => true,
                   "lastName" => "Doe",
                   "mobilePhone" => "0102030405",
                   "nationality" => %{"country" => "Etats-Unis", "countryCode" => "US"},
                   "usageName" => "Josh"
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
      current_password: "wrong",
      password: "new_password",
      confirm_password: "new_password"
    }

    conn = post conn, "/api/v2", query: @query, variables: %{"passwordItem" => password_item}

    assert json_response(conn, 200) ==
             %{
               "data" => %{"updatePassword" => nil},
               "errors" => [
                 %{
                   "details" => [%{"key" => "current_password", "message" => ["is invalid"]}],
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
