defmodule VaeWeb.Schema.Query.AuthoritiesTest do
  use VaeWeb.ConnCase, async: true

  setup %{conn: conn} do
    ExMachina.Sequence.reset()

    user = insert(:user)

    authed_conn = Pow.Plug.assign_current_user(conn, user, otp_app: :vae)

    {:ok, conn: authed_conn}
  end

  @query """
  query ($applicationId: ID!, $geo: GeoInput!, $postalCode: String!) {
    delegatesSearch(applicationId: $applicationId, geo: $geo, postalCode: $postalCode) {
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

    filters = %{
      "applicationId" => application.id,
      "geo" => %{
        "lat" => 43.6043,
        "lng" => 1.44199
      },
      "postalCode" => "31000"
    }

    response =
      get(conn, "/api/v2",
        query: @query,
        variables: filters
      )
      |> json_response(200)

    response["data"]["delegatesSearch"]
    |> Enum.map(&assert_fields_are_not_nil/1)
  end

  def assert_fields_are_not_nil(delegate) do
    ["address", "certifier", "email", "name", "personName", "telephone"]
    |> Enum.map(fn field ->
      assert not is_nil(delegate[field]), "#{field} field is nil"
    end)
  end
end
