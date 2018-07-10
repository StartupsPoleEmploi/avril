defmodule Vae.DelegateControllerTest do
  use Vae.ConnCase

  alias Vae.Vae

  @create_attrs %{}
  @update_attrs %{}
  @invalid_attrs %{}

  def fixture(:delegate) do
    {:ok, delegate} = Vae.create_delegate(@create_attrs)
    delegate
  end

  describe "index" do
    test "lists all delegates", %{conn: conn} do
      conn = get conn, delegate_path(conn, :index)
      assert html_response(conn, 200) =~ "Listing Delegates"
    end
  end

  describe "new delegate" do
    test "renders form", %{conn: conn} do
      conn = get conn, delegate_path(conn, :new)
      assert html_response(conn, 200) =~ "New Delegate"
    end
  end

  describe "create delegate" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post conn, delegate_path(conn, :create), delegate: @create_attrs

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == delegate_path(conn, :show, id)

      conn = get conn, delegate_path(conn, :show, id)
      assert html_response(conn, 200) =~ "Show Delegate"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, delegate_path(conn, :create), delegate: @invalid_attrs
      assert html_response(conn, 200) =~ "New Delegate"
    end
  end

  describe "edit delegate" do
    setup [:create_delegate]

    test "renders form for editing chosen delegate", %{conn: conn, delegate: delegate} do
      conn = get conn, delegate_path(conn, :edit, delegate)
      assert html_response(conn, 200) =~ "Edit Delegate"
    end
  end

  describe "update delegate" do
    setup [:create_delegate]

    test "redirects when data is valid", %{conn: conn, delegate: delegate} do
      conn = put conn, delegate_path(conn, :update, delegate), delegate: @update_attrs
      assert redirected_to(conn) == delegate_path(conn, :show, delegate)

      conn = get conn, delegate_path(conn, :show, delegate)
      assert html_response(conn, 200)
    end

    test "renders errors when data is invalid", %{conn: conn, delegate: delegate} do
      conn = put conn, delegate_path(conn, :update, delegate), delegate: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit Delegate"
    end
  end

  describe "delete delegate" do
    setup [:create_delegate]

    test "deletes chosen delegate", %{conn: conn, delegate: delegate} do
      conn = delete conn, delegate_path(conn, :delete, delegate)
      assert redirected_to(conn) == delegate_path(conn, :index)
      assert_error_sent 404, fn ->
        get conn, delegate_path(conn, :show, delegate)
      end
    end
  end

  defp create_delegate(_) do
    delegate = fixture(:delegate)
    {:ok, delegate: delegate}
  end
end
