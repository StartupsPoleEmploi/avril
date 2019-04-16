defmodule Vae.CertificationTest do
  use Vae.DataCase

  import Vae.Factory

  alias Vae.Certification

  test "Add a certifier on a certification, attach certifier's delegates on certification" do
    certifier = insert!(:certifier_with_delegates) |> Repo.preload(:delegates)

    delegates =
      Certification.changeset(%Certification{}, %{
        label: "certification",
        certifiers: [certifier.id]
      })
      |> Repo.insert!()
      |> Ecto.assoc(:delegates)
      |> Repo.all()
      |> Repo.preload(:process)

    assert delegates == certifier.delegates
  end

  test "Update certifier with more than one delegate on a certification, replace all certification's delegates" do
    certifier_1 = insert!(:certifier_with_delegates) |> Repo.preload(:delegates)
    certifier_2 = insert!(:certifier_with_delegates) |> Repo.preload(:delegates)

    certification =
      Certification.changeset(%Certification{}, %{
        label: "certification",
        certifiers: [certifier_1.id]
      })
      |> Repo.insert!()

    delegates =
      certification
      |> Ecto.assoc(:delegates)
      |> Repo.all()
      |> Repo.preload(:process)

    assert delegates == certifier_1.delegates

    updated_certification =
      Certification.changeset(certification, %{certifiers: [certifier_2.id]})
      |> Repo.update!()

    updated_delegates =
      updated_certification
      |> Ecto.assoc(:delegates)
      |> Repo.all()
      |> Repo.preload(:process)

    assert updated_delegates == certifier_2.delegates
  end
end
