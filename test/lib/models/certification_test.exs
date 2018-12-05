defmodule Vae.CertificationTest do
  use Vae.DataCase

  import Vae.Factory

  alias Vae.{Certification, Certifier, Delegate}

  test "Add a certifier on a certification, attach certifier's delegates on certification" do
    certifier = insert!(:certifier_with_delegates) |> Repo.preload(:delegates)

    changeset =
      Certification.changeset(%Certification{}, %{
        label: "certification",
        certifiers: [certifier.id]
      })

    certification =
      Repo.insert!(changeset)
      |> Repo.preload(:delegates)

    assert certification.delegates == certifier.delegates
  end

  test "Update certifier with more than one delegate on a certification, replace all certification's delegates" do
    certifier_1 = insert!(:certifier_with_delegates) |> Repo.preload(:delegates)
    certifier_2 = insert!(:certifier_with_delegates) |> Repo.preload(:delegates)

    changeset =
      Certification.changeset(%Certification{}, %{
        label: "certification",
        certifiers: [certifier_1.id]
      })

    certification =
      Repo.insert!(changeset)
      |> Repo.preload(:delegates)

    assert certification.delegates == certifier_1.delegates

    update_changeset = Certification.changeset(certification, %{certifiers: [certifier_2.id]})

    updated_certification =
      Repo.update!(update_changeset)
      |> Repo.preload(:delegates)

    assert updated_certification.delegates == certifier_2.delegates
  end
end
