defmodule VaeWeb.Schema.Query.AccountTest do
  use VaeWeb.ConnCase, async: true

  setup %{conn: conn} do
    ExMachina.Sequence.reset()

    user =
      insert(:user, %{
        identity: %{
          gender: "M",
          birthday: ~D[1981-06-24],
          first_name: "John",
          last_name: "Smith",
          usage_name: "Doe",
          email: "john@smith.com",
          home_phone: "0100000000",
          mobile_phone: "0600000000",
          is_handicapped: false,
          birth_place: %{
            city: "Paris",
            country: "France"
          },
          full_address: %{
            city: "Toulouse",
            postal_code: "31000",
            country: "France",
            street: "1, rue de la Bergerie",
            lat: "43.600000",
            lng: "1.433333"
          },
          current_situation: %{
            status: "job_seeker",
            employment_type: "employee",
            register_to_pole_emploi: true,
            register_to_pole_emploi_since: ~D[2019-02-01],
            compensation_type: "pole-emploi"
          },
          nationality: %{
            country: "France",
            country_code: "FR"
          }
        }
      })

    authed_conn = Pow.Plug.assign_current_user(conn, user, otp_app: :vae)

    {:ok, conn: authed_conn}
  end

  @query """
  {
    identity {
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
  test "the profile fields returns the current identity of a user profile", %{conn: conn} do
    conn = get conn, "/api/v2", query: @query

    assert json_response(conn, 200) ==
             %{
               "data" => %{
                 "identity" => %{
                   "birthday" => "1981-06-24",
                   "email" => "john@smith.com",
                   "firstName" => "John",
                   "gender" => "M",
                   "lastName" => "Smith",
                   "birthPlace" => %{
                     "city" => "Paris",
                     "country" => "France",
                     "county" => nil,
                     "lat" => nil,
                     "lng" => nil,
                     "postalCode" => nil,
                     "street" => nil
                   },
                   "fullAddress" => %{
                     "country" => "France",
                     "city" => "Toulouse",
                     "postalCode" => "31000",
                     "street" => "1, rue de la Bergerie",
                     "county" => nil,
                     "lat" => 43.6,
                     "lng" => 1.433333
                   },
                   "currentSituation" => %{
                     "compensationType" => "pole-emploi",
                     "employmentType" => "employee",
                     "registerToPoleEmploi" => true,
                     "registerToPoleEmploiSince" => "2019-02-01",
                     "status" => "job_seeker"
                   },
                   "homePhone" => "0100000000",
                   "isHandicapped" => false,
                   "mobilePhone" => "0600000000",
                   "nationality" => %{"country" => "France", "countryCode" => "FR"},
                   "usageName" => "Doe"
                 }
               }
             }
  end
end
