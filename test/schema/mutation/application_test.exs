defmodule VaeWeb.Mutation.ApplicationTest do
  use VaeWeb.ConnCase, async: true

  setup %{conn: conn} do
    ExMachina.Sequence.reset()

    user = insert(:user)

    authed_conn = Pow.Plug.assign_current_user(conn, user, otp_app: :vae)

    {:ok, conn: authed_conn}
  end

  @query """
  mutation AttachDelegate ($input: AttachDelegateInput!) {
    attachDelegate(input: $input) {
      id
      delegate {
        id
        name
      }
    }
  }
  """
  test "Link a delegate to an application", %{conn: conn} do
    application =
      insert(
        :application_without_delegate,
        %{user: conn.assigns[:current_user]}
      )

    delegate = insert(:delegate)

    attach_delegate_input = %{
      "applicationId" => application.id,
      "delegateId" => delegate.id
    }

    conn =
      post(conn, "/api/v2",
        query: @query,
        variables: %{"input" => attach_delegate_input}
      )

    assert json_response(conn, 200) ==
             %{
               "data" => %{
                 "attachDelegate" => %{
                   "id" => "#{application.id}",
                   "delegate" => %{
                     "id" => "#{delegate.id}",
                     "name" => delegate.name
                   }
                 }
               }
             }
  end

  @query """
  mutation AttachDelegate ($input: AttachDelegateInput!) {
    attachDelegate(input: $input) {
      id
      delegate {
        id
        name
      }
    }
  }
  """
  test "Try to link a delegate to an unknown application fails", %{conn: conn} do
    attach_delegate_input = %{
      "applicationId" => 0,
      "delegateId" => -1
    }

    conn =
      post(conn, "/api/v2",
        query: @query,
        variables: %{"input" => attach_delegate_input}
      )

    assert json_response(conn, 200) ==
             %{
               "data" => %{"attachDelegate" => nil},
               "errors" => [
                 %{
                   "details" => "Application id 0 not found",
                   "locations" => [%{"column" => 0, "line" => 2}],
                   "message" => "La candidature est introuvable",
                   "path" => ["attachDelegate"]
                 }
               ]
             }
  end

  @query """
  mutation AttachDelegate ($input: AttachDelegateInput!) {
    attachDelegate(input: $input) {
      id
      delegate {
        id
        name
      }
    }
  }
  """
  test "Try to link an unknown delegate to an application fails", %{conn: conn} do
    application =
      insert(
        :application_without_delegate,
        %{user: conn.assigns[:current_user]}
      )

    attach_delegate_input = %{
      "applicationId" => application.id,
      "delegateId" => 0
    }

    conn =
      post(conn, "/api/v2",
        query: @query,
        variables: %{"input" => attach_delegate_input}
      )

    assert json_response(conn, 200) ==
             %{
               "data" => %{"attachDelegate" => nil},
               "errors" => [
                 %{
                   "details" => "Delegate id 0 not found",
                   "locations" => [%{"column" => 0, "line" => 2}],
                   "message" => "Le certificateur est introuvable",
                   "path" => ["attachDelegate"]
                 }
               ]
             }
  end
end
