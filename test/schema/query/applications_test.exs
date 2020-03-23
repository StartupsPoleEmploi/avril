defmodule VaeWeb.Schema.Query.ApplicationsTest do
  use VaeWeb.ConnCase, async: true

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
      bookletHash
      insertedAt
    }
  }
  """
  test "the application field returns a list from a given user", %{conn: conn} do
    date = NaiveDateTime.utc_now()
    user = conn.assigns[:current_user]
    applications = insert_list(2, :application, %{user: user, inserted_at: date})

    conn = get conn, "/api/v2", query: @query

    response = json_response(conn, 200)

    assert length(response["data"]["applications"]) == length(applications)
  end
end
