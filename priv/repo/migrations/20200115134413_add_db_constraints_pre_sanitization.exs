defmodule Vae.Repo.Migrations.AddDbConstraintsPreSanitization do
  use Ecto.Migration

  def change do
    create unique_index(:certifier_certifications, [:certifier_id, :certification_id])
    create unique_index(:certifiers_delegates, [:certifier_id, :delegate_id])
    create unique_index(:rome_certifications, [:rome_id, :certification_id])

    Ecto.Adapters.SQL.query!(
      Vae.Repo, """
        DELETE   FROM certifications_delegates T1
          USING       certifications_delegates T2
        WHERE  T1.ctid    > T2.ctid -- keep the "older" ones
          AND  T1.delegate_id    = T2.delegate_id
          AND  T1.certification_id = T2.certification_id;
      """
    ) |> IO.inspect()

    create unique_index(:certifications_delegates, [:delegate_id, :certification_id])
  end
end
