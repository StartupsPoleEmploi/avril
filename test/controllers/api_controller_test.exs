defmodule Vae.ApiControllerTest do
  use Vae.ConnCase

  import Vae.Factory

  test "init cerfa with empty value", %{conn: conn} do
    date = Date.utc_today()
    application = insert!(:application, date)

    response =
      Plug.Conn.assign(conn, :current_application, application)
      |> get("/api/booklet?hash=1234")
      |> json_response(200)

    assert %{
             "data" => %{
               "certificationLabel" => "BT my certification",
               "identity" => %{
                 "address" => %{
                   "city" => "Paris",
                   "country" => "France",
                   "postalCode" => "75000",
                   "street" => "Street 1, Street 2"
                 },
                 "birth" => %{"city" => "Dijon", "date" => "2019-11-21"},
                 "cellPhoneNumber" => "0102030405",
                 "email" => "john@doe.com",
                 "firstNames" => ["John"],
                 "lastName" => "Doe",
                 "sex" => "M"
               }
             },
             "status" => "ok"
           } == response
  end
end
