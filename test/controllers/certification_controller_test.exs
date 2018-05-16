defmodule Vae.CertificationControllerTest do
  use Vae.ConnCase

  test "redirection to detailed process with lat lng" do
    params = %{rncp_id: "1829", lat: "48.86", lng: "2.3413"}

    conn =
      build_conn()
      |> get(certification_path(build_conn(), :index, params))

    assert redirected_to(conn) =~ "/processes/27?certification=2799&delegate=14"
  end

  test "redirection to general process" do
    params = %{rncp_id: "1212", rome_code: "F1107"}

    conn =
      build_conn()
      |> get(certification_path(build_conn(), :index, params))

    assert redirected_to(conn) =~ "/processes"
  end

  test "redirection to certifications with rome" do
    params = %{rome_code: "F1107"}

    conn =
      build_conn()
      |> get(certification_path(build_conn(), :index, params))

    assert redirected_to(conn) =~ "/certifications"
  end
end
