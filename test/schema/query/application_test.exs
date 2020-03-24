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
end
