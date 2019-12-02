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

    assert %Vae.Booklet.Cerfa{
             certification_name: "BT my certification",
             civility: %Vae.Booklet.Civility{
               birth_place: "Dijon",
               birthday: date,
               city: "75000 Paris, France",
               country: "France",
               email: "john@doe.com",
               first_name: "John",
               full_address: "Street 1, Street 2, 75000 Paris, France",
               gender: "M",
               home_phone: nil,
               last_name: "Doe",
               mobile_phone: "0102030405",
               postal_code: "75000",
               street_address: "Street 1, Street 2",
               usage_name: nil
             },
             education: nil,
             experiences: [
               %Vae.Booklet.Experience{
                 company_name: nil,
                 employment_type: nil,
                 end_date: ~D[2019-06-30],
                 full_address: nil,
                 job_industry: nil,
                 skills: [],
                 start_date: ~D[2018-12-31],
                 title: "Chargé d'affaires Vidéosurveillance, alarme, gestion des accès ",
                 uuid: nil,
                 week_hours_duration: 35
               },
               %Vae.Booklet.Experience{
                 company_name: nil,
                 employment_type: nil,
                 end_date: ~D[2017-12-31],
                 full_address: nil,
                 job_industry: nil,
                 skills: [],
                 start_date: ~D[2015-09-30],
                 title: "President Sas",
                 uuid: nil,
                 week_hours_duration: 35
               },
               %Vae.Booklet.Experience{
                 company_name: nil,
                 employment_type: nil,
                 end_date: ~D[2014-08-31],
                 full_address: nil,
                 job_industry: nil,
                 skills: [],
                 start_date: ~D[2012-12-31],
                 title: "Ingénieur d'affaires",
                 uuid: nil,
                 week_hours_duration: 35
               },
               %Vae.Booklet.Experience{
                 company_name: nil,
                 employment_type: nil,
                 end_date: ~D[2012-08-31],
                 full_address: nil,
                 job_industry: nil,
                 skills: [],
                 start_date: ~D[2009-12-31],
                 title: "Entrepreneur et opérateur certifié",
                 uuid: nil,
                 week_hours_duration: 35
               }
             ]
           } == Repo.get(Vae.Application, application.id) |> Map.get(:booklet_1)

    assert %{
             "status" => "ok",
             "data" => %{
               "certification_name" => "BT my certification",
               "civility" => %{
                 "birth_place" => "Dijon",
                 "birthday" => "2019-12-02",
                 "city" => "75000 Paris, France",
                 "country" => "France",
                 "email" => "john@doe.com",
                 "first_name" => "John",
                 "full_address" => "Street 1, Street 2, 75000 Paris, France",
                 "gender" => "M",
                 "home_phone" => nil,
                 "last_name" => "Doe",
                 "mobile_phone" => "0102030405",
                 "postal_code" => "75000",
                 "street_address" => "Street 1, Street 2",
                 "usage_name" => nil
               },
               "education" => nil,
               "experiences" => [
                 %{
                   "company_name" => nil,
                   "employment_type" => nil,
                   "end_date" => "2019-06-30",
                   "full_address" => nil,
                   "job_industry" => nil,
                   "skills" => [],
                   "start_date" => "2018-12-31",
                   "title" => "Chargé d'affaires Vidéosurveillance, alarme, gestion des accès ",
                   "uuid" => nil,
                   "week_hours_duration" => 35
                 },
                 %{
                   "company_name" => nil,
                   "employment_type" => nil,
                   "end_date" => "2017-12-31",
                   "full_address" => nil,
                   "job_industry" => nil,
                   "skills" => [],
                   "start_date" => "2015-09-30",
                   "title" => "President Sas",
                   "uuid" => nil,
                   "week_hours_duration" => 35
                 },
                 %{
                   "company_name" => nil,
                   "employment_type" => nil,
                   "end_date" => "2014-08-31",
                   "full_address" => nil,
                   "job_industry" => nil,
                   "skills" => [],
                   "start_date" => "2012-12-31",
                   "title" => "Ingénieur d'affaires",
                   "uuid" => nil,
                   "week_hours_duration" => 35
                 },
                 %{
                   "company_name" => nil,
                   "employment_type" => nil,
                   "end_date" => "2012-08-31",
                   "full_address" => nil,
                   "job_industry" => nil,
                   "skills" => [],
                   "start_date" => "2009-12-31",
                   "title" => "Entrepreneur et opérateur certifié",
                   "uuid" => nil,
                   "week_hours_duration" => 35
                 }
               ]
             }
           } ==
             response
  end

  test "init cerfa with booklet values", %{conn: conn} do
    date = Date.utc_today()
    application = build(:application_with_booklet, date)

    response =
      Plug.Conn.assign(conn, :current_application, application)
      |> get("/api/booklet?hash=123456")
      |> json_response(200)

    assert %{
             "status" => "ok",
             "data" => %{
               "education" => %{
                 "courses" => [%{"label" => "CAPES"}, %{"label" => "CACES"}],
                 "degree" => "I",
                 "diplomas" => [%{"label" => "CAP Boucher"}, %{"label" => "BTS Boulanger"}],
                 "grade" => "A"
               },
               "experiences" => [
                 %{
                   "uuid" => "1",
                   "company_name" => "Butcher Market",
                   "employment_type" => "A",
                   "end_date" => "2018-11-30",
                   "full_address" => "Centre commercial Binard",
                   "job_industry" => "H",
                   "skills" => [
                     %{"label" => "Découpe de charcuterie"},
                     %{"label" => "Affutage"},
                     %{"label" => "Découpe de poulet"},
                     %{"label" => "Rotisserie"}
                   ],
                   "start_date" => "2019-11-30",
                   "title" => "Responsable Boucherie",
                   "week_hours_duration" => 35
                 },
                 %{
                   "uuid" => "2",
                   "company_name" => "Baker Market",
                   "employment_type" => "D",
                   "end_date" => "2017-11-30",
                   "full_address" => "Centre commercial 2e gauche",
                   "job_industry" => "H",
                   "skills" => [%{"label" => "Glacage"}, %{"label" => "Pate brisée"}],
                   "start_date" => "2018-11-29",
                   "title" => "Responsable Patisserie",
                   "week_hours_duration" => 35
                 }
               ],
               "certification_name" => "BT my certification",
               "civility" => %{
                 "birth_place" => "Saint-Malo",
                 "birthday" => "2019-12-02",
                 "city" => "Saint-Malo",
                 "country" => "FR",
                 "email" => "john@smith.com",
                 "first_name" => "John",
                 "full_address" => nil,
                 "gender" => "M",
                 "home_phone" => "0300000000",
                 "last_name" => "Doe",
                 "mobile_phone" => "0600000000",
                 "postal_code" => "35000",
                 "street_address" => "Rue de la Pierre",
                 "usage_name" => "Smith"
               }
             }
           } ==
             response
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

    assert response["data"]["certification_name"] == "BT my certification"
    assert response["data"]["civility"]["gender"] == "M"
    assert response["data"]["civility"]["birthday"] == "#{date}"
    assert response["data"]["civility"]["birth_place"] == "Dijon"

    # Set
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
        "full_address" => "rue mousette, 84000 Pierre Saint Martin, FR",
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

    # Update
    params = %{
      "certification_name" => "plip",
      "civility" => %{
        "gender" => "M",
        "birthday" => "2000-12-30",
        "birth_place" => "Paris",
        "first_name" => "Pierre",
        "last_name" => "Faux",
        "usage_name" => "",
        "email" => "pierre@faux.com",
        "home_phone" => "0200000000",
        "mobile_phone" => "0700000000",
        "full_address" => "rue Fierre Paux, 75000 Paris, FR",
        "street_address" => "rue Fierre Paux",
        "postal_code" => "75000",
        "city" => "Paris",
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

    params = %{
      "education" => %{
        "grade" => "C",
        "degree" => "D",
        "diplomas" => [
          %{
            "label" => "BTS Plombier"
          }
        ],
        "courses" => [
          %{
            "label" => "Permis B"
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
