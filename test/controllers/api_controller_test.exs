defmodule Vae.ApiControllerTest do
  use Vae.ConnCase

  import Vae.Factory

  test "init cerfa with application values", %{conn: conn} do
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
                 "birth" => %{"city" => "Dijon", "date" => "#{date}"},
                 "cellPhoneNumber" => "0102030405",
                 "email" => "john@doe.com",
                 "firstNames" => ["John"],
                 "lastName" => "Doe",
                 "sex" => "M"
               },
               "experiences" => [
                 %{
                   "activities" => [],
                   "category" => nil,
                   "companyAddress" => nil,
                   "companyName" => "Ads Securite ",
                   "contractType" => nil,
                   "hours" => 35,
                   "periods" => ["2018-12-31", "2019-06-30"],
                   "role" => "Chargé d'affaires Vidéosurveillance, alarme, gestion des accès "
                 },
                 %{
                   "activities" => [],
                   "category" => nil,
                   "companyAddress" => nil,
                   "companyName" => "Suissa Elec",
                   "contractType" => nil,
                   "hours" => 35,
                   "periods" => ["2015-09-30", "2017-12-31"],
                   "role" => "President Sas"
                 },
                 %{
                   "activities" => [],
                   "category" => nil,
                   "companyAddress" => nil,
                   "companyName" => "Ecus Ondulique",
                   "contractType" => nil,
                   "hours" => 35,
                   "periods" => ["2012-12-31", "2014-08-31"],
                   "role" => "Ingénieur d'affaires"
                 },
                 %{
                   "activities" => [],
                   "category" => nil,
                   "companyAddress" => nil,
                   "companyName" => "Dan'diag",
                   "contractType" => nil,
                   "hours" => 35,
                   "periods" => ["2009-12-31", "2012-08-31"],
                   "role" => "Entrepreneur et opérateur certifié"
                 }
               ]
             },
             "status" => "ok"
           } == response
  end
end
