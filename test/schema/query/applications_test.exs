defmodule VaeWeb.Schema.Query.ApplicationsTest do
  use VaeWeb.ConnCase, async: true

  alias Vae.Authorities

  setup %{conn: conn} do
    ExMachina.Sequence.reset()

    user = insert(:user)

    authed_conn = Pow.Plug.assign_current_user(conn, user, otp_app: :vae)

    {:ok, conn: authed_conn}
  end

  @query """
  {
    applications {
      id
      bookletHash
      insertedAt
    }
  }
  """
  test "the application field returns an empty list if the user hasn't applied yet", %{conn: conn} do
    conn = get conn, "/api/v2", query: @query

    assert json_response(conn, 200) == %{
             "data" => %{
               "applications" => []
             }
           }
  end

  @query """
  {
    applications {
      id
    }
  }
  """
  test "the application field returns an application list from a given user", %{conn: conn} do
    date = NaiveDateTime.utc_now()
    user = conn.assigns[:current_user]
    applications = insert_list(2, :application, %{user: user, inserted_at: date})

    conn = get conn, "/api/v2", query: @query

    response = json_response(conn, 200)

    assert length(response["data"]["applications"]) == length(applications)

    assert Enum.map(applications, &"#{&1.id}") --
             Enum.map(response["data"]["applications"], & &1["id"]) == []
  end

  @query """
  {
    applications {
      id
      bookletHash
      insertedAt
      submittedAt
      delegate {
        id
        name
        personName
        email
        address
        telephone
        certifier {
          name
        }
      }
      certification {
        id
        slug
        acronym
        label
        level
      }
    }
  }
  """
  test "the application field returns the fields that the client needs for a given user", %{
    conn: conn
  } do
    application = insert(:application, %{user: conn.assigns[:current_user]})

    conn = get conn, "/api/v2", query: @query

    assert json_response(conn, 200) == %{
             "data" => %{
               "applications" => [
                 %{
                   "id" => "#{application.id}",
                   "bookletHash" => application.booklet_hash,
                   "insertedAt" => to_iso8601(application.inserted_at),
                   "submittedAt" => to_iso8601(application.submitted_at),
                   "delegate" => %{
                     "id" => "#{application.delegate.id}",
                     "name" => application.delegate.name,
                     "personName" => application.delegate.person_name,
                     "email" => application.delegate.email,
                     "address" => application.delegate.address,
                     "telephone" => application.delegate.telephone,
                     "certifier" => %{
                       "name" =>
                         Authorities.get_first_certifier_from_delegate(application.delegate).name
                     }
                   },
                   "certification" => %{
                     "id" => "#{application.certification.id}",
                     "slug" => application.certification.slug,
                     "acronym" => application.certification.acronym,
                     "label" => application.certification.label,
                     "level" => "#{application.certification.level}"
                   }
                 }
               ]
             }
           }
  end
end
