defmodule Vae.CertificationControllerTest do
  use Vae.ConnCase

  import Vae.Factory

  alias Vae.{Certification, Rome}

  test "redirection to detailed process with lat lng" do
    certifier = insert!(:certifier_with_one_delegate) |> Repo.preload(:delegates)

    certification =
      Certification.changeset(%Certification{}, %{
        label: "certification",
        rncp_id: "1829",
        certifiers: [certifier.id]
      })
      |> Repo.insert!()
      |> Repo.preload(:delegates)

    params = %{rncp_id: "1829", lat: "48.86", lng: "2.3413"}

    conn =
      build_conn()
      |> get(certification_path(build_conn(), :index, params))

    assert redirected_to(conn) =~ "/processes?certification=#{certification.id}"
  end

  test "redirection to general process" do
    certifier = insert!(:certifier_with_one_delegate) |> Repo.preload(:delegates)

    rome =
      Rome.changeset(%Rome{}, %{
        code: "F1107",
        label: "Rome test"
      })
      |> Repo.insert!()

    Certification.changeset(%Certification{}, %{
      label: "certification",
      rncp_id: "1829",
      certifiers: [certifier.id],
      romes: [rome.id]
    })
    |> Repo.insert!()

    params = %{rncp_id: "1829", rome_code: "F1107"}

    conn =
      build_conn()
      |> get(certification_path(build_conn(), :index, params))

    assert redirected_to(conn) =~ "/processes"
  end

  test "redirection to certifications with rome" do
    certifier = insert!(:certifier_with_one_delegate) |> Repo.preload(:delegates)

    rome =
      Rome.changeset(%Rome{}, %{
        code: "F1107",
        label: "Rome test"
      })
      |> Repo.insert!()

    Certification.changeset(%Certification{}, %{
      label: "certification",
      rncp_id: "1829",
      certifiers: [certifier.id],
      romes: [rome.id]
    })
    |> Repo.insert!()
    |> Repo.preload(:delegates)

    params = %{rome_code: "F1107"}

    conn =
      build_conn()
      |> get(certification_path(build_conn(), :index, params))

    assert redirected_to(conn) =~ "/certifications"
  end
end
