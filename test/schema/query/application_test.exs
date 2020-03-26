defmodule VaeWeb.Schema.Query.ApplicationsTest do
  use VaeWeb.ConnCase, async: true

  setup %{conn: conn} do
    ExMachina.Sequence.reset()

    user = insert(:user)

    authed_conn = Pow.Plug.assign_current_user(conn, user, otp_app: :vae)

    {:ok, conn: authed_conn}
  end

  @query """
  query ($id: ID!){
    application(id: $id) {
      id
    }
  }
  """
  @variables %{"id" => 0}
  test "application field returns a null application if application is not found", %{conn: conn} do
    conn = get conn, "/api/v2", query: @query, variables: @variables

    assert json_response(conn, 200) == %{
             "data" => %{
               "application" => nil
             }
           }
  end

  @query """
  query ($id: ID!){
    application(id: $id) {
      id
    }
  }
  """
  test "application field returns application from an id", %{conn: conn} do
    application = insert(:application, %{user: conn.assigns[:current_user]})
    conn = get conn, "/api/v2", query: @query, variables: %{"id" => application.id}

    assert json_response(conn, 200) == %{
             "data" => %{
               "application" => %{
                 "id" => "#{application.id}"
               }
             }
           }
  end

  @query """
  query ($id: ID!){
    application(id: $id) {
      id
    }
  }
  """
  test "application field returns a nil application if the application does not belong to the user",
       %{conn: conn} do
    application = insert(:application, %{user: insert(:user)})
    conn = get conn, "/api/v2", query: @query, variables: %{"id" => application.id}

    assert json_response(conn, 200) == %{
             "data" => %{
               "application" => nil
             }
           }
  end

  @query """
  query ($id: ID!){
    application(id: $id) {
      id
      bookletHash
      insertedAt
      submittedAt
      certification {
        id
        acronym
        label
        level
        slug
      }
      delegate {
        id
        name
        personName
        telephone
        address
        email
        certifier {
          name
        }
      }
    }
  }
  """
  test "Returns a complete representation of an application", %{conn: conn} do
    submitted_at = NaiveDateTime.utc_now()
    inserted_at = Timex.shift(submitted_at, days: -5)

    application =
      insert(:application, %{
        user: conn.assigns[:current_user],
        inserted_at: inserted_at,
        submitted_at: submitted_at
      })

    conn = get conn, "/api/v2", query: @query, variables: %{"id" => application.id}

    assert json_response(conn, 200) == %{
             "data" => %{
               "application" => %{
                 "id" => "#{application.id}",
                 "bookletHash" => application.booklet_hash,
                 "insertedAt" => to_iso8601(application.inserted_at),
                 "submittedAt" => to_iso8601(application.submitted_at),
                 "certification" => %{
                   "id" => "#{application.certification.id}",
                   "acronym" => application.certification.acronym,
                   "label" => application.certification.label,
                   "level" => "#{application.certification.level}",
                   "slug" => application.certification.slug
                 },
                 "delegate" => %{
                   "id" => "#{application.delegate.id}",
                   "name" => application.delegate.name,
                   "personName" => application.delegate.person_name,
                   "telephone" => application.delegate.telephone,
                   "address" => application.delegate.address,
                   "email" => application.delegate.email,
                   "certifier" => %{
                     "name" =>
                       Vae.Authorities.get_first_certifier_from_delegate(application.delegate).name
                   }
                 }
               }
             }
           }
  end

  @query """
    query ($id: ID!) {
      application(id: $id) {
        meeting {
          name
          academy_id
          meeting_id
          place
          address
          postal_code
          city
          target
          remaining_places
          start_date
          end_date
        }
      }
    }
  """
  test "Application fields return a meeting if there is", %{conn: conn} do
    start_date = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
    end_date = Timex.shift(start_date, hours: 3)

    meeting = %{
      name: "Meeting name",
      academy_id: 2,
      meeting_id: 122,
      place: "Meeting place",
      address: "meeting address",
      postal_code: "12345",
      city: "Meeting's city",
      target: "You",
      remaining_places: "5",
      start_date: start_date,
      end_date: end_date
    }

    application =
      insert(:application, %{
        user: conn.assigns[:current_user],
        meeting: meeting
      })

    conn = get conn, "/api/v2", query: @query, variables: %{"id" => application.id}

    assert json_response(conn, 200) == %{
             "data" => %{
               "application" => %{
                 "meeting" => %{
                   "academy_id" => 2,
                   "address" => "meeting address",
                   "city" => "Meeting's city",
                   "end_date" => NaiveDateTime.to_iso8601(end_date),
                   "meeting_id" => 122,
                   "name" => "Meeting name",
                   "place" => "Meeting place",
                   "postal_code" => "12345",
                   "remaining_places" => 5,
                   "start_date" => NaiveDateTime.to_iso8601(start_date),
                   "target" => "You"
                 }
               }
             }
           }
  end
end
