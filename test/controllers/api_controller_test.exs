defmodule VaeWeb.ApiControllerTest do
  use VaeWeb.ConnCase

  import Vae.Factory

  test "init cerfa with application values", %{conn: conn} do
    date = Date.utc_today()

    {application, delegate} =
      insert!(:application, date)
      |> put_delegate_with_certifier()

    response =
      Plug.Conn.assign(conn, :current_application, application)
      |> get("/api/booklet?hash=123456")
      |> json_response(200)

    certifier_name =
      delegate.certifiers
      |> hd()
      |> Map.get(:name)

    expected_response = %{
      "status" => "ok",
      "data" => %{
        "certification_name" => "BT my certification",
        "certififier_name" => certifier_name,
        "civility" => %{
          "birth_place" => %{
            "city" => "Dijon",
            "country" => nil,
            "domTom" => nil,
            "lat" => nil,
            "lng" => nil,
            "postal_code" => nil,
            "street" => nil
          },
          "nationality" => nil,
          "current_situation" => nil,
          "is_handicapped" => false,
          "birthday" => "#{date}",
          "email" => "john@doe.com",
          "first_name" => "John",
          "full_address" => %{
            "city" => "Paris",
            "country" => "France",
            "domTom" => nil,
            "lat" => nil,
            "lng" => nil,
            "postal_code" => "75000",
            "street" => "Street 1, Street 2"
          },
          "gender" => "m",
          "home_phone" => nil,
          "last_name" => "Doe",
          "mobile_phone" => "0102030405",
          "usage_name" => nil
        },
        "education" => nil,
        "experiences" => [
          %{
            "company_name" => "Ads Securite ",
            "employment_type" => 1,
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
            "company_name" => "Suissa Elec",
            "employment_type" => 1,
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
            "company_name" => "Ecus Ondulique",
            "employment_type" => 1,
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
            "company_name" => "Dan'diag",
            "employment_type" => 1,
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

    assert response["data"]["certification_name"] == "BT my certification"
    assert response["data"]["certifier_name"] == certifier_name
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
        "certififier_name" => "Certifier",
        "education" => %{
          "courses" => [%{"label" => "CAPES"}, %{"label" => "CACES"}],
          "degree" => 1,
          "diplomas" => [%{"label" => "CAP Boucher"}, %{"label" => "BTS Boulanger"}],
          "grade" => 1
        },
        "experiences" => [
          %{
            "uuid" => "1",
            "company_name" => "Butcher Market",
            "employment_type" => 1,
            "full_address" => %{
              "city" => "Saint-Malo",
              "country" => "FR",
              "domTom" => nil,
              "lat" => 32.1111,
              "lng" => 2.1111,
              "postal_code" => "35000",
              "street" => "Centre commercial Binard"
            },
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
            "employment_type" => 4,
            "full_address" => %{
              "city" => "Saint-Malo",
              "country" => "FR",
              "domTom" => nil,
              "lat" => 32.1111,
              "lng" => 2.1111,
              "postal_code" => "35000",
              "street" => "Centre commercial Binard"
            },
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
          "nationality" => %{
            "country" => "France",
            "country_code" => "FR"
          },
          "birth_place" => %{
            "city" => "Saint-Malo",
            "country" => nil,
            "domTom" => nil,
            "lat" => nil,
            "lng" => nil,
            "postal_code" => nil,
            "street" => nil
          },
          "birthday" => "#{date}",
          "email" => "john@smith.com",
          "first_name" => "John",
          "full_address" => %{
            "city" => "Saint-Malo",
            "country" => "France",
            "street" => "23, Rue Jean Jaures",
            "postal_code" => "35000",
            "domTom" => nil,
            "lat" => 45.3333,
            "lng" => 2.4323
          },
          "current_situation" => nil,
          "is_handicapped" => nil,
          "gender" => "m",
          "home_phone" => "0300000000",
          "last_name" => "Doe",
          "mobile_phone" => "0600000000",
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

    {application, _delegate} =
      insert!(:application, date)
      |> put_delegate_with_certifier()

    conn = Plug.Conn.assign(conn, :current_application, application)

    response =
      conn
      |> get("/api/booklet?hash=123456")
      |> json_response(200)

    assert response["data"]["certification_name"] == "BT my certification"
    assert response["data"]["civility"]["gender"] == "m"
    assert response["data"]["civility"]["birthday"] == "#{date}"

    assert response["data"]["civility"]["full_address"] == %{
             "city" => "Paris",
             "country" => "France",
             "lat" => nil,
             "lng" => nil,
             "postal_code" => "75000",
             "street" => "Street 1, Street 2",
             "domTom" => nil
           }

    assert response["data"]["civility"]["birth_place"] == %{
             "city" => "Dijon",
             "country" => nil,
             "domTom" => nil,
             "lat" => nil,
             "lng" => nil,
             "postal_code" => nil,
             "street" => nil
           }

    # Set
    params = %{
      "certification_name" => "plop",
      "civility" => %{
        "nationality" => %{
          "country" => "Espagne",
          "country_code" => "ES"
        },
        "gender" => "f",
        "birthday" => "2000-11-30",
        "birth_place" => %{
          "city" => "Dijon",
          "country" => "France",
          "domTom" => nil,
          "lat" => 47.323,
          "lng" => 5.04198
        },
        "current_situation" => %{
          "status" => "employee",
          "employment_type" => "CDI",
          "register_to_pole_emploi" => "true",
          "register_to_pole_emploi_since" => "2019-11-01",
          "compensation_type" => "AAH"
        },
        "is_handicapped" => "true",
        "first_name" => "Jeanne",
        "last_name" => "Daux",
        "usage_name" => "Martins",
        "email" => "jeanne@daux.com",
        "home_phone" => "0100000000",
        "mobile_phone" => "0600000000",
        "full_address" => %{
          "city" => "Levallois-Perret",
          "country" => "France",
          "lat" => 48.8928,
          "lng" => 2.2942,
          "postalCode" => "92300",
          "street" => "44 Rue Jean Jaurès",
          "domTom" => nil
        }
      }
    }

    Plug.Conn.assign(conn, :current_application, application)
    |> put("/api/booklet?hash=123456", params)
    |> json_response(200)

    updated_booklet =
      Repo.get(Vae.UserApplication, application.id)
      |> Map.get(:booklet_1)

    assert_struct_by_params(updated_booklet, params, :civility)

    # Update
    params = %{
      "certification_name" => "plip",
      "civility" => %{
        "nationality" => %{
          "country" => "France",
          "country_code" => "FR"
        },
        "gender" => "m",
        "birthday" => "2000-12-30",
        "birth_place" => %{
          "city" => "Paris",
          "country" => "France",
          "domTom" => nil,
          "lat" => 52.323,
          "lng" => 6.04198
        },
        "current_situation" => %{
          "status" => "job_seeker",
          "employment_type" => nil,
          "register_to_pole_emploi" => "true",
          "compensation_type" => "RSA"
        },
        "is_handicapped" => "false",
        "first_name" => "Pierre",
        "last_name" => "Faux",
        "usage_name" => "",
        "email" => "pierre@faux.com",
        "home_phone" => "0200000000",
        "mobile_phone" => "0700000000",
        "full_address" => %{
          "city" => "Paris",
          "country" => "France",
          "lat" => 21.8928,
          "lng" => 1.2942,
          "postalCode" => "75000",
          "street" => "rue Fierre Paux"
        }
      }
    }

    Plug.Conn.assign(conn, :current_application, application)
    |> put("/api/booklet?hash=123456", params)
    |> json_response(200)

    updated_booklet =
      Repo.get(Vae.UserApplication, application.id)
      |> Map.get(:booklet_1)

    assert_struct_by_params(updated_booklet, params, :civility)
  end

  def assert_struct_by_params(struct, params, root_key) do
    struct
    |> Map.get(root_key)
    |> Map.from_struct()
    |> Map.keys()
    |> Enum.each(fn key ->
      case get_in(struct, [Access.key(root_key), Access.key(key)]) do
        nil ->
          assert "" == "#{params[Atom.to_string(root_key)][Atom.to_string(key)]}"

        %Date{} = value ->
          assert "#{value}" == "#{params[Atom.to_string(root_key)][Atom.to_string(key)]}"

        %{__struct__: _struct_name} = value ->
          assert_struct_by_params(
            Map.get(struct, root_key),
            params[Atom.to_string(root_key)],
            key
          )

        value ->
          assert "#{value}" ==
                   "#{params[Atom.to_string(root_key)][Atom.to_string(key)]}"
      end
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

    {application, _delegate} =
      insert!(:application, date)
      |> put_delegate_with_certifier()

    conn = Plug.Conn.assign(conn, :current_application, application)

    response =
      conn
      |> get("/api/booklet?hash=123456")
      |> json_response(200)

    assert response["data"]["education"] == nil

    params = %{
      "education" => %{
        "grade" => 2,
        "degree" => 2,
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
      Repo.get(Vae.UserApplication, application.id)
      |> Map.get(:booklet_1)

    assert_classifications(updated_booklet, params, :education)

    params = %{
      "education" => %{
        "grade" => 3,
        "degree" => 3,
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
      Repo.get(Vae.UserApplication, application.id)
      |> Map.get(:booklet_1)

    assert_classifications(updated_booklet, params, :education)
  end

  test "update booklet experiences", %{conn: conn} do
    date = Date.utc_today()

    {application, _delegate} =
      insert!(:application, date)
      |> put_delegate_with_certifier()

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
          "full_address" => %{
            city: "La Pierre",
            country: "FR",
            domTom: nil,
            lat: 32.1111,
            lng: 2.1111,
            postal_code: "87600",
            street: "25, rue de la Pompe"
          },
          "job_industry" => "B",
          "employment_type" => 3,
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
          "full_address" => %{
            "city" => "La Pompe",
            "country" => "FR",
            "domTom" => nil,
            "lat" => 32.1111,
            "lng" => 2.1111,
            "postal_code" => "86000",
            "street" => "10, rue de la Pierre"
          },
          "job_industry" => "B",
          "employment_type" => 3,
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
      Repo.get(Vae.UserApplication, application.id)
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
          "job_industry",
          "employment_type"
        ])
        |> Map.values()
        |> Enum.map(&"#{&1}")
      end)
      |> Enum.sort()

    given_experiences =
      updated_booklet.experiences
      |> Enum.flat_map(fn experience ->
        experience
        |> Map.take([
          :title,
          :company_name,
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
          "full_address" => %{
            "city" => "La Pierre",
            "country" => "FR",
            "domTom" => nil,
            "lat" => 32.1111,
            "lng" => 2.1111,
            "postal_code" => "87600",
            "street" => "25, rue de la Pompe"
          },
          "job_industry" => "B",
          "employment_type" => 3,
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
          "full_address" => %{
            "city" => "La Pompe",
            "country" => "FR",
            "domTom" => nil,
            "lat" => 32.1111,
            "lng" => 2.1111,
            "postal_code" => "86000",
            "street" => "10, rue de la Pierre"
          },
          "job_industry" => "B",
          "employment_type" => 3,
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
      Repo.get(Vae.UserApplication, application.id)
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
          "job_industry",
          "employment_type"
        ])
        |> Map.values()
        |> Enum.map(&"#{&1}")
      end)
      |> Enum.sort()

    given_experiences =
      updated_booklet.experiences
      |> Enum.flat_map(fn experience ->
        experience
        |> Map.take([
          :title,
          :company_name,
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
        contract_type: 3,
        start_date: ~D[2019-01-02],
        end_date: ~D[2019-01-05],
        week_hours_duration: 35
      },
      %{
        label: "foo",
        company_name: "bar",
        full_address: nil,
        contract_type: 2,
        start_date: ~D[2019-01-02],
        end_date: ~D[2019-01-05],
        week_hours_duration: 35
      },
      %{
        label: "foo",
        company_name: "bar",
        full_address: nil,
        contract_type: 3,
        start_date: ~D[2019-01-02],
        end_date: ~D[2019-01-05],
        week_hours_duration: 35
      },
      %{
        label: "baz",
        company_name: "bar",
        full_address: nil,
        contract_type: 2,
        start_date: ~D[2019-01-02],
        end_date: ~D[2019-01-05],
        week_hours_duration: 35
      }
    ]

    assert experiences
           |> Vae.ApiController.group_experiences()
           |> Vae.ApiController.map_experiences()
           |> Enum.sort_by(& &1.employment_type) ==
             [
               %Vae.Booklet.Experience{
                 company_name: "bar",
                 employment_type: 1,
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
                 employment_type: 1,
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
                 employment_type: 1,
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
    given_experiences = Enum.sort_by(given_experiences, fn xp -> xp["company_name"] end)
    expected_experiences = Enum.sort_by(expected_experiences, fn xp -> xp["company_name"] end)

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

  defp put_delegate_with_certifier(application) do
    with delegate <-
           insert!(:certifier_with_one_delegate)
           |> Vae.Repo.preload(:delegates)
           |> Map.get(:delegates)
           |> hd()
           |> Vae.Repo.preload(:certifiers),
         {:ok, application} <-
           application
           |> Vae.Repo.preload(:delegate)
           |> Ecto.Changeset.change()
           |> Ecto.Changeset.put_assoc(:delegate, delegate)
           |> Vae.Repo.update() do
      {application, delegate}
    end
  end
end
