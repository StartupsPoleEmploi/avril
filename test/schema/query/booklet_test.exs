defmodule VaeWeb.Schema.Query.BookletTest do
  use VaeWeb.ConnCase, async: true

  setup %{conn: conn} do
    ExMachina.Sequence.reset()

    user = insert(:user_with_proven_experiences)

    authed_conn = Pow.Plug.assign_current_user(conn, user, otp_app: :vae)

    {:ok, conn: authed_conn}
  end

  @query """
  query ($applicationId: ID!){
    booklet(applicationId: $applicationId) {
      insertedAt
      updatedAt
      completedAt
      certificationName
      certifierName
      experiences {
        title
        company_name
        employment_type
        periods {
          start_date
          end_date
          total_hours
        }
      }
      civility {
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
  }
  """
  test "booklet field returns a booklet initialized by application", %{conn: conn} do
    application =
      insert(:application, %{
        user: conn.assigns[:current_user],
        certifiers: [build(:certifier)]
      })

    conn = get conn, "/api/v2", query: @query, variables: %{"applicationId" => application.id}

    assert json_response(conn, 200) == %{
             "data" => %{
               "booklet" => %{
                 "certificationName" => Vae.Certification.name(application.certification),
                 "certifierName" => Vae.UserApplication.certifier_name(application),
                 "civility" => %{
                   "birthPlace" => %{
                     "city" => "Paris",
                     "country" => "France",
                     "county" => nil,
                     "lat" => nil,
                     "lng" => nil,
                     "postalCode" => nil,
                     "street" => nil
                   },
                   "birthday" => "1981-06-24",
                   "currentSituation" => %{
                     "compensationType" => "pole-emploi",
                     "employmentType" => "employee",
                     "registerToPoleEmploi" => true,
                     "registerToPoleEmploiSince" => "2019-02-01",
                     "status" => "job_seeker"
                   },
                   "email" => "john@smith.com",
                   "firstName" => "John",
                   "fullAddress" => %{
                     "city" => "Toulouse",
                     "country" => "France",
                     "county" => nil,
                     "lat" => 43.6,
                     "lng" => 1.433333,
                     "postalCode" => "31000",
                     "street" => "1, rue de la Bergerie"
                   },
                   "gender" => "M",
                   "homePhone" => "0100000000",
                   "isHandicapped" => false,
                   "lastName" => "Smith",
                   "mobilePhone" => "0600000000",
                   "nationality" => %{"country" => "France", "countryCode" => "FR"},
                   "usageName" => "Doe"
                 },
                 "completedAt" => nil,
                 "insertedAt" => nil,
                 "updatedAt" => nil,
                 "experiences" => [
                   %{
                     "company_name" => "Avril Production",
                     "employment_type" => 1,
                     "periods" => [
                       %{
                         "end_date" => "2017-10-25",
                         "start_date" => "2017-10-23",
                         "total_hours" => 24
                       },
                       %{
                         "end_date" => "2017-09-20",
                         "start_date" => "2017-09-04",
                         "total_hours" => 88
                       }
                     ],
                     "title" => "Assistant réalisateur adjoint"
                   },
                   %{
                     "company_name" => "PE Production",
                     "employment_type" => 1,
                     "periods" => [
                       %{
                         "end_date" => "2017-11-25",
                         "start_date" => "2017-11-01",
                         "total_hours" => 89
                       }
                     ],
                     "title" => "Réalisateur"
                   }
                 ]
               }
             }
           }
  end
end
