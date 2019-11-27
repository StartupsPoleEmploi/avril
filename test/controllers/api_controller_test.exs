defmodule Vae.ApiControllerTest do
  use Vae.ConnCase

  import Vae.Factory

  test "init cerfa with application values", %{conn: conn} do
    date = Date.utc_today()

    application = insert!(:application, date)

    response =
      Plug.Conn.assign(conn, :current_application, application)
      |> get("/api/booklet?hash=123456")
      |> json_response(200)

    assert %{
             "data" => %{
               "certificationLabel" => "BT my certification",
               "identity" => %{
                 "address" => %{
                   "city" => "Paris",
                   "country" => "France",
                   "postalCode" => "75000",
                   "street" => "Street 1, Street 2"
                 },
                 "birth" => %{"city" => "Dijon", "date" => "#{date}"},
                 "cellPhoneNumber" => "0102030405",
                 "email" => "john@doe.com",
                 "firstNames" => ["John"],
                 "lastName" => "Doe",
                 "sex" => "M"
               },
               "experiences" => [
                 %{
                   "activities" => [],
                   "category" => nil,
                   "companyAddress" => nil,
                   "companyName" => "Ads Securite ",
                   "contractType" => nil,
                   "hours" => 35,
                   "periods" => ["2018-12-31", "2019-06-30"],
                   "role" => "Chargé d'affaires Vidéosurveillance, alarme, gestion des accès "
                 },
                 %{
                   "activities" => [],
                   "category" => nil,
                   "companyAddress" => nil,
                   "companyName" => "Suissa Elec",
                   "contractType" => nil,
                   "hours" => 35,
                   "periods" => ["2015-09-30", "2017-12-31"],
                   "role" => "President Sas"
                 },
                 %{
                   "activities" => [],
                   "category" => nil,
                   "companyAddress" => nil,
                   "companyName" => "Ecus Ondulique",
                   "contractType" => nil,
                   "hours" => 35,
                   "periods" => ["2012-12-31", "2014-08-31"],
                   "role" => "Ingénieur d'affaires"
                 },
                 %{
                   "activities" => [],
                   "category" => nil,
                   "companyAddress" => nil,
                   "companyName" => "Dan'diag",
                   "contractType" => nil,
                   "hours" => 35,
                   "periods" => ["2009-12-31", "2012-08-31"],
                   "role" => "Entrepreneur et opérateur certifié"
                 }
               ],
               "education" => nil
             },
             "status" => "ok"
           } == response
  end

  test "init cerfa with booklet values", %{conn: conn} do
    date = Date.utc_today()
    application = build(:application_with_booklet, date)

    response =
      Plug.Conn.assign(conn, :current_application, application)
      |> get("/api/booklet?hash=123456")
      |> json_response(200)

    assert %{
             "data" => %{
               "certificationLabel" => "BT my certification",
               "identity" => %{
                 "address" => %{
                   "city" => "Saint-Malo",
                   "country" => "FR",
                   "postalCode" => "35000",
                   "street" => "Rue de la Pierre"
                 },
                 "birth" => %{"city" => "Saint-Malo", "date" => "#{date}"},
                 "cellPhoneNumber" => "0600000000",
                 "email" => "john@smith.com",
                 "firstNames" => ["John"],
                 "lastName" => "Doe",
                 "sex" => "M"
               },
               "experiences" => [
                 %{
                   "activities" => [
                     "Découpe de charcuterie",
                     "Affutage",
                     "Découpe de poulet",
                     "Rotisserie"
                   ],
                   "category" => "H",
                   "companyAddress" => "Centre commercial Binard",
                   "companyName" => "Butcher Market",
                   "contractType" => "A",
                   "hours" => 35,
                   "periods" => ["2019-11-30", "2018-11-30"],
                   "role" => "Responsable Boucherie"
                 },
                 %{
                   "activities" => [
                     "Glacage",
                     "Pate brisée"
                   ],
                   "category" => "H",
                   "companyAddress" => "Centre commercial 2e gauche",
                   "companyName" => "Baker Market",
                   "contractType" => "D",
                   "hours" => 35,
                   "periods" => ["2018-11-29", "2017-11-30"],
                   "role" => "Responsable Patisserie"
                 }
               ],
               "education" => %{
                 "latestCourseLevel" => "A",
                 "latestDegree" => "I",
                 "relatedDegrees" => ["CAP Boucher", "BTS Boulanger"],
                 "trainings" => ["CAPES", "CACES"]
               }
             },
             "status" => "ok"
           } == response
  end

  test "update a nil application", %{conn: conn} do
    conn
    |> get("/api/booklet?hash=456780000")
    |> html_response(404)
  end

  test "update booklet civilty", %{conn: conn} do
    date = Date.utc_today()
    application = insert!(:application, date)

    conn = Plug.Conn.assign(conn, :current_application, application)

    response =
      conn
      |> get("/api/booklet?hash=123456")
      |> json_response(200)

    assert response["data"]["certificationLabel"] == "BT my certification"
    assert response["data"]["identity"]["sex"] == "M"
    assert response["data"]["identity"]["birth"]["date"] == "#{date}"
    assert response["data"]["identity"]["birth"]["city"] == "Dijon"

    params = %{
      "certification_name" => "plop",
      "civility" => %{
        "gender" => "F",
        "birthday" => "2000-11-30",
        "birth_place" => "Marseille",
        "first_name" => "Jeanne",
        "last_name" => "Daux",
        "usage_name" => "Martins",
        "email" => "jeanne@daux.com",
        "home_phone" => "0100000000",
        "mobile_phone" => "0600000000",
        "street_address" => "rue mousette",
        "postal_code" => "84000",
        "city" => "Pierre Saint Martin",
        "country" => "FR"
      }
    }

    Plug.Conn.assign(conn, :current_application, application)
    |> put("/api/booklet?hash=123456", params)
    |> json_response(200)

    updated_booklet =
      Repo.get(Vae.Application, application.id)
      |> Map.get(:booklet_1)

    updated_booklet.civility
    |> Map.from_struct()
    |> Map.keys()
    |> Enum.each(fn key ->
      assert "#{get_in(updated_booklet, [Access.key(:civility), Access.key(key)])}" ==
               params["civility"][Atom.to_string(key)]
    end)
  end

  test "update booklet education", %{conn: conn} do
    date = Date.utc_today()
    application = insert!(:application, date)

    conn = Plug.Conn.assign(conn, :current_application, application)

    response =
      conn
      |> get("/api/booklet?hash=123456")
      |> json_response(200)

    assert response["data"]["education"] == nil

    params = %{
      "education" => %{
        "grade" => "B",
        "degree" => "F",
        "diplomas" => [
          %{
            "label" => "BTS Charcutier"
          },
          %{
            "label" => "CAP Chauffeur"
          }
        ],
        "courses" => [
          %{
            "label" => "Permis B"
          },
          %{
            "label" => "Permis C"
          }
        ]
      }
    }

    Plug.Conn.assign(conn, :current_application, application)
    |> put("/api/booklet?hash=123456", params)
    |> json_response(200)

    updated_booklet =
      Repo.get(Vae.Application, application.id)
      |> Map.get(:booklet_1)

    updated_booklet.education
    |> Map.from_struct()
    |> Map.keys()
    |> Enum.each(fn key ->
      case get_in(updated_booklet, [Access.key(:education), Access.key(key)]) do
        xs when is_list(xs) ->
          assert Kernel.length(xs) == Kernel.length(params["education"][Atom.to_string(key)])

          assert(
            Enum.map(xs, & &1.label) |> Enum.sort() ==
              Enum.map(params["education"][Atom.to_string(key)], & &1["label"]) |> Enum.sort()
          )

        s ->
          assert s == params["education"][Atom.to_string(key)]
      end
    end)
  end

  test "update booklet experiences", %{conn: conn} do
    date = Date.utc_today()
    application = insert!(:application, date)

    conn = Plug.Conn.assign(conn, :current_application, application)

    response =
      conn
      |> get("/api/booklet?hash=123456")
      |> json_response(200)

    assert response["data"]["education"] == nil

    params = %{
      "experiences" => [
        %{
          "title" => "Responsable GD",
          "company_name" => "Peclerc",
          "full_address" => "25, rue de la Pompe 87600 La Pierre",
          "job_industry" => "B",
          "employment_type" => "C",
          "start_date" => "2019-11-25",
          "end_date" => "2018-10-01",
          "week_hours_duration" => "35",
          "skills" => [
            %{
              "label" => "Mise en place"
            },
            %{
              "label" => "Gestion des stocks"
            },
            %{
              "label" => "Management 10 personnes"
            }
          ]
        },
        %{
          "title" => "Agent Polyvalent",
          "company_name" => "Peclerc",
          "full_address" => "10, rue de la Pierre, 86000 La Pompe",
          "job_industry" => "B",
          "employment_type" => "C",
          "start_date" => "2018-10-01",
          "end_date" => "2015-01-01",
          "week_hours_duration" => "35",
          "skills" => [
            %{
              "label" => "Réception marchandise"
            },
            %{
              "label" => "Réapro"
            }
          ]
        }
      ]
    }

    Plug.Conn.assign(conn, :current_application, application)
    |> put("/api/booklet?hash=123456", params)
    |> json_response(200)

    updated_booklet =
      Repo.get(Vae.Application, application.id)
      |> Map.get(:booklet_1)

    assert Kernel.length(updated_booklet.experiences) == Kernel.length(params["experiences"])

    expected_skills =
      Enum.flat_map(params["experiences"], & &1["skills"])
      |> Enum.flat_map(fn skill ->
        skill
        |> Map.values()
      end)
      |> Enum.sort()

    given_skills =
      Enum.flat_map(updated_booklet.experiences, & &1.skills)
      |> Enum.flat_map(fn skill ->
        skill
        |> Map.from_struct()
        |> Map.values()
      end)
      |> Enum.sort()

    assert given_skills == expected_skills

    expected_experiences =
      params["experiences"]
      |> Enum.flat_map(fn experience ->
        experience
        |> Map.take([
          "title",
          "company_name",
          "full_address",
          "job_industry",
          "employment_type",
          "start_date",
          "end_date",
          "week_hours_duration"
        ])
        |> Map.values()
      end)
      |> Enum.sort()

    given_experiences =
      updated_booklet.experiences
      |> Enum.flat_map(fn experience ->
        experience
        |> Map.take([
          :title,
          :company_name,
          :full_address,
          :job_industry,
          :employment_type,
          :start_date,
          :end_date,
          :week_hours_duration
        ])
        |> Map.values()
        |> Enum.map(&"#{&1}")
      end)
      |> Enum.sort()

    assert expected_experiences == given_experiences
  end
end
