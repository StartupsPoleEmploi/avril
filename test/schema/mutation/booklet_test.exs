defmodule VaeWeb.Schema.Mutation.BookletTest do
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
          compensationType
        }
        nationality {
          country
          countryCode
        }
      }
      experiences {
        uuid
        title
        companyName
        jobIndustry
        fullAddress {
          city
          county
          country
          lat
          lng
          street
          postalCode
        }
        employmentType
        skills { label }
        periods {
          startDate
          endDate
          totalHours
          weekHoursDuration
        }
      }
      education {
        grade
        degree
        diplomas { label }
        courses { label }
      }
    }
  }
  """

  @mutation_query """
  mutation SetBooklet ($input: BookletInput!) {
    setBooklet(input: $input) {
      insertedAt
      updatedAt
      completedAt
      certificationName
      certifierName
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
          compensationType
        }
        nationality {
          country
          countryCode
        }
      }
      experiences {
        uuid
        title
        companyName
        jobIndustry
        fullAddress {
          city
          county
          country
          lat
          lng
          street
          postalCode
        }
        employmentType
        skills { label }
        periods {
          startDate
          endDate
          totalHours
          weekHoursDuration
        }
      }
      education {
        grade
        degree
        diplomas { label }
        courses { label }
      }
    }
  }
  """
  test "Set booklet", %{conn: conn} do
    application =
      insert(:application_with_complete_booklet, %{
        user: conn.assigns[:current_user],
        certifiers: [build(:certifier)]
      })

    booklet_input = %{
      "applicationId" => application.id,
      "booklet" => %{
        "civility" => %{
          "birthPlace" => %{
            "city" => "Saint-Malo",
            "country" => "France",
            "county" => "Ille-et-Vilaine",
            "lat" => 48.6472,
            "lng" => -2.00884,
            "postalCode" => "35400",
            "street" => "1, rue de la fontaine"
          },
          "birthday" => "1991-06-24",
          "currentSituation" => %{
            "compensationType" => "0",
            "employmentType" => "partial",
            "registerToPoleEmploi" => false,
            "status" => "CDI"
          },
          "email" => "jane@smith.com",
          "firstName" => "Jane",
          "fullAddress" => %{
            "city" => "Saint-Malo",
            "country" => "France",
            "county" => "Ille-et-Vilaine",
            "lat" => 48.6472,
            "lng" => -2.00884,
            "postalCode" => "35400",
            "street" => "1, rue de la fontaine"
          },
          "gender" => "F",
          "homePhone" => "0100000001",
          "isHandicapped" => false,
          "lastName" => "Smith",
          "mobilePhone" => "0600000001",
          "nationality" => %{"country" => "France", "countryCode" => "FR"},
          "usageName" => "Dane"
        },
        "education" => %{
          "grade" => 1,
          "degree" => 2,
          "diplomas" => [
            %{"label" => "Diploma 1"},
            %{"label" => "Diploma 2"}
          ],
          "courses" => [
            %{"label" => "Course 1"},
            %{"label" => "Course 2"}
          ]
        },
        "experiences" => [
          %{
            "uuid" => "3",
            "title" => "Exp 1",
            "companyName" => "CP1",
            "jobIndustry" => "JI 1",
            "employmentType" => 1,
            "fullAddress" => %{
              "city" => "Paris",
              "county" => "Paris",
              "country" => "France",
              "lat" => 48.866667,
              "lng" => 2.333333,
              "street" => "22, rue de la coulée verte",
              "postalCode" => "75000"
            },
            "skills" => [
              %{"label" => "skill 1"},
              %{"label" => "skill 2"}
            ],
            "periods" => [
              %{
                "startDate" => "2019-01-01",
                "endDate" => "2019-02-01",
                "weekHoursDuration" => 35,
                "totalHours" => 174
              },
              %{
                "startDate" => "2019-03-01",
                "endDate" => "2019-04-01",
                "weekHoursDuration" => 35,
                "totalHours" => 174
              }
            ]
          },
          %{
            "uuid" => "4",
            "title" => "Exp 2",
            "companyName" => "CP2",
            "jobIndustry" => "JI 2",
            "employmentType" => 2,
            "fullAddress" => %{
              "city" => "Toulouse",
              "county" => "Haute-Garonne",
              "country" => "France",
              "lat" => 43.6043,
              "lng" => 1.44199,
              "street" => "23, rue de la coulée jaune",
              "postalCode" => "31000"
            },
            "skills" => [
              %{"label" => "skill 3"},
              %{"label" => "skill 4"}
            ],
            "periods" => [
              %{
                "startDate" => "2020-01-01",
                "endDate" => "2020-02-01",
                "weekHoursDuration" => 35,
                "totalHours" => 174
              }
            ]
          }
        ]
      }
    }

    update_conn =
      post(conn, "/api/v2", query: @mutation_query, variables: %{"input" => booklet_input})

    given_booklet = json_response(update_conn, 200)["data"]["setBooklet"]
    expected_booklet = booklet_input["booklet"]

    assert given_booklet["experiences"] == expected_booklet["experiences"]
    assert given_booklet["education"] == expected_booklet["education"]
    assert given_booklet["civility"] == expected_booklet["civility"]

    get_conn =
      get(conn, "/api/v2", query: @query, variables: %{"applicationId" => application.id})

    get_booklet = json_response(get_conn, 200)["data"]["booklet"]
    assert get_booklet["experiences"] == expected_booklet["experiences"]
    assert get_booklet["education"] == expected_booklet["education"]
    assert get_booklet["civility"] == expected_booklet["civility"]
  end
end
