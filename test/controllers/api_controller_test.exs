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

    expected_response = %{
      "status" => "ok",
      "data" => %{
        "certification_name" => "BT my certification",
        "civility" => %{
          "birth_place" => "Dijon",
          "birthday" => "2019-12-04",
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
            "full_address" => nil,
            "job_industry" => nil,
            "skills" => [],
            "periods" => [
              %{
                "start_date" => "2018-12-31",
                "end_date" => "2019-06-30",
                "week_hours_duration" => 35
              }
            ],
            "title" => "Chargé d'affaires Vidéosurveillance, alarme, gestion des accès ",
            "uuid" => nil
          },
          %{
            "company_name" => nil,
            "employment_type" => nil,
            "full_address" => nil,
            "job_industry" => nil,
            "skills" => [],
            "periods" => [
              %{
                "start_date" => "2015-09-30",
                "end_date" => "2017-12-31",
                "week_hours_duration" => 35
              }
            ],
            "title" => "President Sas",
            "uuid" => nil
          },
          %{
            "company_name" => nil,
            "employment_type" => nil,
            "full_address" => nil,
            "job_industry" => nil,
            "skills" => [],
            "periods" => [
              %{
                "start_date" => "2012-12-31",
                "end_date" => "2014-08-31",
                "week_hours_duration" => 35
              }
            ],
            "title" => "Ingénieur d'affaires",
            "uuid" => nil
          },
          %{
            "company_name" => nil,
            "employment_type" => nil,
            "full_address" => nil,
            "job_industry" => nil,
            "skills" => [],
            "periods" => [
              %{
                "start_date" => "2009-12-31",
                "end_date" => "2012-08-31",
                "week_hours_duration" => 35
              }
            ],
            "title" => "Entrepreneur et opérateur certifié",
            "uuid" => nil
          }
        ]
      }
    }

    assert_status_is_ok?(response)
    assert_civility(response, expected_response)
    assert_experiences(response, expected_response)
  end

  test "init cerfa with booklet values", %{conn: conn} do
    date = Date.utc_today()
    application = build(:application_with_booklet, date)

    response =
      Plug.Conn.assign(conn, :current_application, application)
      |> get("/api/booklet?hash=123456")
      |> json_response(200)

    expected_response = %{
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
            "full_address" => "Centre commercial Binard",
            "job_industry" => "H",
            "periods" => [
              %{
                "start_date" => "2019-11-30",
                "end_date" => "2018-11-30",
                "week_hours_duration" => 35
              }
            ],
            "skills" => [
              %{"label" => "Découpe de charcuterie"},
              %{"label" => "Affutage"},
              %{"label" => "Découpe de poulet"},
              %{"label" => "Rotisserie"}
            ],
            "title" => "Responsable Boucherie"
          },
          %{
            "uuid" => "2",
            "company_name" => "Baker Market",
            "employment_type" => "D",
            "full_address" => "Centre commercial 2e gauche",
            "job_industry" => "H",
            "periods" => [
              %{
                "start_date" => "2018-11-29",
                "end_date" => "2017-11-30",
                "week_hours_duration" => 35
              }
            ],
            "skills" => [%{"label" => "Glacage"}, %{"label" => "Pate brisée"}],
            "title" => "Responsable Patisserie"
          }
        ],
        "certification_name" => "BT my certification",
        "civility" => %{
          "birth_place" => "Saint-Malo",
          "birthday" => "2019-12-04",
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
    }

    assert_status_is_ok?(response)
    assert_civility(response, expected_response)
    assert_experiences(response, expected_response)
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

    assert_struct_by_params(updated_booklet, params, :civility)

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

    assert_struct_by_params(updated_booklet, params, :civility)
  end

  def assert_struct_by_params(struct, params, root_key) do
    struct
    |> Map.get(root_key)
    |> Map.from_struct()
    |> Map.keys()
    |> Enum.each(fn key ->
      assert "#{get_in(struct, [Access.key(root_key), Access.key(key)])}" ==
               params[Atom.to_string(root_key)][Atom.to_string(key)]
    end)
  end

  def assert_classifications(struct, params, root_key) do
    struct
    |> Map.get(root_key)
    |> Map.from_struct()
    |> Map.keys()
    |> Enum.each(fn key ->
      case get_in(struct, [Access.key(root_key), Access.key(key)]) do
        xs when is_list(xs) ->
          assert Kernel.length(xs) ==
                   Kernel.length(params[Atom.to_string(root_key)][Atom.to_string(key)])

          assert(
            Enum.map(xs, & &1.label) |> Enum.sort() ==
              Enum.map(params[Atom.to_string(root_key)][Atom.to_string(key)], & &1["label"])
              |> Enum.sort()
          )

        s ->
          assert s == params[Atom.to_string(root_key)][Atom.to_string(key)]
      end
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

    assert_classifications(updated_booklet, params, :education)

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

    assert_classifications(updated_booklet, params, :education)
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
          "periods" => [
            %{
              "start_date" => "2019-11-25",
              "end_date" => "2018-10-01",
              "week_hours_duration" => "35"
            },
            %{
              "start_date" => "2015-11-25",
              "end_date" => "2017-10-01",
              "week_hours_duration" => "20"
            }
          ],
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
          "periods" => [
            %{
              "start_date" => "2018-10-01",
              "end_date" => "2015-01-01",
              "week_hours_duration" => "35"
            }
          ],
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

    expected_periods =
      Enum.flat_map(params["experiences"], & &1["periods"])
      |> Enum.flat_map(fn skill ->
        skill
        |> Map.values()
      end)
      |> Enum.sort()

    given_periods =
      Enum.flat_map(updated_booklet.experiences, & &1.periods)
      |> Enum.flat_map(fn period ->
        period
        |> Map.from_struct()
        |> Map.values()
        |> Enum.map(&"#{&1}")
      end)
      |> Enum.sort()

    assert given_periods == expected_periods

    expected_experiences =
      params["experiences"]
      |> Enum.flat_map(fn experience ->
        experience
        |> Map.take([
          "title",
          "company_name",
          "full_address",
          "job_industry",
          "employment_type"
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
          :employment_type
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
          "periods" => [
            %{
              "start_date" => "2019-11-25",
              "end_date" => "2018-10-01",
              "week_hours_duration" => "35"
            }
          ],
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
          "periods" => [
            %{
              "start_date" => "2018-10-01",
              "end_date" => "2015-01-01",
              "week_hours_duration" => "35"
            }
          ],
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

    expected_periods =
      Enum.flat_map(params["experiences"], & &1["periods"])
      |> Enum.flat_map(fn skill ->
        skill
        |> Map.values()
      end)
      |> Enum.sort()

    given_periods =
      Enum.flat_map(updated_booklet.experiences, & &1.periods)
      |> Enum.flat_map(fn period ->
        period
        |> Map.from_struct()
        |> Map.values()
        |> Enum.map(&"#{&1}")
      end)
      |> Enum.sort()

    assert given_periods == expected_periods

    expected_experiences =
      params["experiences"]
      |> Enum.flat_map(fn experience ->
        experience
        |> Map.take([
          "title",
          "company_name",
          "full_address",
          "job_industry",
          "employment_type"
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
          :employment_type
        ])
        |> Map.values()
        |> Enum.map(&"#{&1}")
      end)
      |> Enum.sort()

    assert expected_experiences == given_experiences
  end

  test "Group experiences and concat durations" do
    experiences = [
      %{
        label: "foo",
        company_name: "bar",
        full_address: nil,
        contract_type: "cdi",
        start_date: ~D[2019-01-02],
        end_date: ~D[2019-01-05],
        week_hours_duration: 35
      },
      %{
        label: "foo",
        company_name: "bar",
        full_address: nil,
        contract_type: "cdi",
        start_date: ~D[2019-01-02],
        end_date: ~D[2019-01-05],
        week_hours_duration: 35
      },
      %{
        label: "foo",
        company_name: "bar",
        full_address: nil,
        contract_type: "cdd",
        start_date: ~D[2019-01-02],
        end_date: ~D[2019-01-05],
        week_hours_duration: 35
      },
      %{
        label: "baz",
        company_name: "bar",
        full_address: nil,
        contract_type: "cdi",
        start_date: ~D[2019-01-02],
        end_date: ~D[2019-01-05],
        week_hours_duration: 35
      }
    ]

    assert experiences
           |> Vae.ApiController.group_experiences()
           |> Vae.ApiController.map_experiences() ==
             [
               %Vae.Booklet.Experience{
                 company_name: "bar",
                 employment_type: "cdi",
                 full_address: nil,
                 job_industry: nil,
                 periods: [
                   %Vae.Booklet.Experience.Period{
                     end_date: ~D[2019-01-05],
                     start_date: ~D[2019-01-02],
                     week_hours_duration: 35
                   }
                 ],
                 skills: [],
                 title: "baz",
                 uuid: nil
               },
               %Vae.Booklet.Experience{
                 company_name: "bar",
                 employment_type: "cdd",
                 full_address: nil,
                 job_industry: nil,
                 periods: [
                   %Vae.Booklet.Experience.Period{
                     end_date: ~D[2019-01-05],
                     start_date: ~D[2019-01-02],
                     week_hours_duration: 35
                   }
                 ],
                 skills: [],
                 title: "foo",
                 uuid: nil
               },
               %Vae.Booklet.Experience{
                 company_name: "bar",
                 employment_type: "cdi",
                 full_address: nil,
                 job_industry: nil,
                 periods: [
                   %Vae.Booklet.Experience.Period{
                     end_date: ~D[2019-01-05],
                     start_date: ~D[2019-01-02],
                     week_hours_duration: 35
                   },
                   %Vae.Booklet.Experience.Period{
                     end_date: ~D[2019-01-05],
                     start_date: ~D[2019-01-02],
                     week_hours_duration: 35
                   }
                 ],
                 skills: [],
                 title: "foo",
                 uuid: nil
               }
             ]
  end

  def assert_status_is_ok?(%{"status" => status}) do
    assert status == "ok"
  end

  def assert_civility(%{"data" => %{"civility" => given_civility}}, %{
        "data" => %{"civility" => expected_civility}
      }) do
    assert given_civility == expected_civility
  end

  def assert_experiences(
        %{"data" => %{"experiences" => given_experiences}},
        %{"data" => %{"experiences" => expected_experiences}}
      ) do
    assert_experiences_meta(given_experiences, expected_experiences)
    assert_experiences_skills(given_experiences, expected_experiences)
    assert_experiences_periods(given_experiences, expected_experiences)
  end

  def assert_experiences_meta(given_experiences, expected_experiences) do
    given_meta = extract_meta_from_experiences(given_experiences)

    expected_meta = extract_meta_from_experiences(expected_experiences)

    assert given_meta == expected_meta
  end

  def extract_meta_from_experiences(experiences) do
    experiences
    |> Enum.map(&extract_meta_from_experience/1)
    |> Enum.sort_by(& &1["title"])
  end

  def extract_meta_from_experience(experience) do
    experience
    |> Map.take([
      "company_name",
      "employment_type",
      "full_address",
      "job_industry",
      "title",
      "uuid"
    ])
  end

  def assert_experiences_skills(given_experiences, expected_experiences) do
    given_skills = extract_skills(given_experiences)

    expected_skills = extract_skills(expected_experiences)

    assert given_skills == expected_skills
  end

  def extract_skills(experiences) do
    experiences
    |> Enum.flat_map(fn experience ->
      experience["skills"]
      |> Enum.map(&Map.values/1)
    end)
    |> Enum.sort()
  end

  def assert_experiences_periods(given_experiences, expected_experiences) do
    given_periods = extract_periods(given_experiences)

    expected_periods = extract_periods(expected_experiences)

    assert given_periods == expected_periods
  end

  def extract_periods(experiences) do
    experiences
    |> Enum.flat_map(fn experience ->
      experience["periods"]
    end)
    |> Enum.sort_by(& &1["start_date"])
  end
end
