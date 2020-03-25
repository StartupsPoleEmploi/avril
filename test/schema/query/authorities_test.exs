defmodule VaeWeb.Schema.Query.AuthoritiesTest do
  use VaeWeb.ConnCase, async: true

  setup %{conn: conn} do
    ExMachina.Sequence.reset()

    user = insert(:user)

    authed_conn = Pow.Plug.assign_current_user(conn, user, otp_app: :vae)

    {:ok, conn: authed_conn}
  end

  @query """
  query ($applicationId: ID!) {
    delegateSearch(applicationId: $applicationId) {
      name
      address
      email
      personName
      telephone
      certifier {
        name
      }
    }
  }
  """
  test "search delegates from an application ID return a delegate list", %{conn: conn} do
    application = insert(:application, %{user: conn.assigns[:current_user]})

    response =
      get(conn, "/api/v2",
        query: @query,
        variables: %{"applicationId" => application.id}
      )
      |> json_response(200)

    response["data"]["delegateSearch"]
    |> Enum.map(&assert_fields_are_not_nil/1)
  end

  def assert_fields_are_not_nil(delegate) do
    ["address", "certifier", "email", "name", "personName", "telephone"]
    |> Enum.map(fn field ->
      assert not is_nil(delegate[field])
    end)
  end
end
