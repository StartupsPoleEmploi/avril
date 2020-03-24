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
end
