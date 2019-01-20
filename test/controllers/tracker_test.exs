defmodule Vae.TrackerTest do
  use Vae.ConnCase

  alias Vae.JobSeeker

  test "no start to track when coming from another source than email", %{conn: conn} do
    conn = get(conn, "/")

    assert is_nil(get_session(conn, :js_id))
  end

  test "start to track when coming from email campaign", %{conn: conn} do
    job_seeker =
      %JobSeeker{
        email: "foo@bar.com"
      }
      |> Vae.Repo.insert!()

    conn = get(conn, "/?js_id=#{job_seeker.id}")

    assert job_seeker.id == get_session(conn, :js_id)
  end

  test "start tracking known user" do
    job_seeker =
      %JobSeeker{
        email: "foo@bar.com"
      }
      |> Vae.Repo.insert!()

    conn =
      build_conn()
      |> get("/?js_id=#{job_seeker.id}")
      |> get("/")

    assert job_seeker.id == get_session(conn, :js_id)
  end

  test "add search tracking", %{conn: conn} do
    job_seeker =
      %JobSeeker{
        email: "foo@bar.com",
        analytics: [
          %Vae.Analytic{
            date: Date.from_iso8601!("2018-09-10"),
            visits: [
              %Vae.Visit{
                certification_id: nil,
                delegate_id: nil,
                path_info: nil,
                search: %Vae.Search{
                  geolocation_text: "Marseille 1er Arrondissement",
                  lat: "48.86",
                  lng: "2.3413",
                  profession: "Aide à domicile",
                  rome_code: "K1404"
                }
              }
            ]
          }
        ]
      }
      |> Vae.Repo.insert!()

    conn
    |> get("/?js_id=#{job_seeker.id}")
    |> get(
      "/certifications?_utf8=✓&search%5Bprofession%5D=Comptabilité+%28Comptable%2C+...%29&search%5Brome_code%5D=M1203&search%5Bgeolocation_text%5D=Paris+1er+Arrondissement&search%5Blat%5D=48.86&search%5Blng%5D=2.3413"
    )

    updated_job_seeker = Vae.Repo.get(JobSeeker, job_seeker.id)

    assert Kernel.length(updated_job_seeker.analytics) == 2

    today_analytics =
      updated_job_seeker.analytics
      |> Enum.filter(fn analytic ->
        Date.compare(analytic.date, Date.utc_today()) == :eq
      end)
      |> Kernel.hd()

    assert Kernel.length(today_analytics.visits) == 1

    expected_visit = %Vae.Visit{
      certification_id: nil,
      delegate_id: nil,
      path_info: ["certifications"],
      search: %Vae.Search{
        geolocation_text: "Paris 1er Arrondissement",
        lat: "48.86",
        lng: "2.3413",
        profession: "Comptabilité (Comptable, ...)",
        rome_code: "M1203"
      }
    }

    assert [expected_visit] -- today_analytics.visits == []
  end

  test "update visits with search tracking", %{conn: conn} do
    certification =
      %Vae.Certification{
        label: "test certification",
        description: "Certification description"
      }
      |> Vae.Repo.insert!()

    delegate =
      %Vae.Delegate{
        name: "test delegate"
      }
      |> Vae.Repo.insert!()

    process =
      %Vae.Process{
        name: "test process"
      }
      |> Vae.Repo.insert!()
      |> Vae.Repo.preload(:delegates)
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:delegates, [delegate])
      |> Vae.Repo.update!()

    job_seeker =
      %JobSeeker{
        email: "foo@bar.com",
        analytics: [
          %Vae.Analytic{
            date: Date.from_iso8601!("2018-09-10"),
            visits: [
              %Vae.Visit{
                certification_id: nil,
                delegate_id: nil,
                path_info: nil,
                search: %Vae.Search{
                  geolocation_text: "Marseille 1er Arrondissement",
                  lat: "48.86",
                  lng: "2.3413",
                  profession: "Aide à domicile",
                  rome_code: "K1404"
                }
              }
            ]
          },
          %Vae.Analytic{
            date: Date.utc_today(),
            visits: [
              %Vae.Visit{
                certification_id: nil,
                delegate_id: nil,
                path_info: nil,
                search: %Vae.Search{
                  geolocation_text: "Puteaux",
                  lat: "48.86",
                  lng: "2.3413",
                  profession: "Plombier",
                  rome_code: "K1405"
                }
              }
            ]
          }
        ]
      }
      |> Vae.Repo.insert!()

    conn
    |> get("/?js_id=#{job_seeker.id}")
    |> get(
      "/certifications?_utf8=✓&search%5Bprofession%5D=Comptabilité+%28Comptable%2C+...%29&search%5Brome_code%5D=M1203&search%5Bgeolocation_text%5D=Paris+1er+Arrondissement&search%5Blat%5D=48.86&search%5Blng%5D=2.3413"
    )
    |> get(
      "/processes/#{process.id}?certification=#{certification.id}&delegate=#{delegate.id}&lat=48.86&lng=2.3413"
    )

    updated_job_seeker = Vae.Repo.get(JobSeeker, job_seeker.id)

    assert Kernel.length(updated_job_seeker.analytics) == 2

    expected_visits = [
      %Vae.Visit{
        certification_id: certification.id,
        delegate_id: delegate.id,
        path_info: ["processes", "#{process.id}"],
        search: nil
      },
      %Vae.Visit{
        certification_id: nil,
        delegate_id: nil,
        path_info: ["certifications"],
        search: %Vae.Search{
          geolocation_text: "Paris 1er Arrondissement",
          lat: "48.86",
          lng: "2.3413",
          profession: "Comptabilité (Comptable, ...)",
          rome_code: "M1203"
        }
      },
      %Vae.Visit{
        certification_id: nil,
        delegate_id: nil,
        path_info: nil,
        search: %Vae.Search{
          geolocation_text: "Puteaux",
          lat: "48.86",
          lng: "2.3413",
          profession: "Plombier",
          rome_code: "K1405"
        }
      }
    ]

    today_analytics =
      updated_job_seeker.analytics
      |> Enum.filter(fn analytic ->
        Date.compare(analytic.date, Date.utc_today()) == :eq
      end)
      |> Kernel.hd()

    assert Kernel.length(today_analytics.visits) == 3
    assert today_analytics.visits -- expected_visits == []
  end
end
