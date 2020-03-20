defmodule VaeWeb.CertificationControllerTest do
  use VaeWeb.ConnCase

  import Vae.Factory

  alias Vae.{Certification, Rome}

  test "redirection to detailed process with lat lng" do
    certifier = insert!(:certifier_with_one_delegate) |> Repo.preload(:delegates)

    certification =
      Certification.changeset(%Certification{}, %{
        label: "test certification",
        rncp_id: "test",
        certifiers: [certifier.id]
      })
      |> Repo.insert!()
      |> Repo.preload(:delegates)

    params = %{rncp_id: "test", lat: "48.86", lng: "2.3413"}

    conn =
      build_conn()
      |> get(certification_path(build_conn(), :index, params))

    assert redirected_to(conn) =~ "/processes?certification=#{certification.id}"
  end
end
