defmodule Vae.Repo.Migrations.SetVisibilityToTrue do
  use Ecto.Migration

  def change do
    visibility_true = fn delegate ->
      changeset = Vae.Delegate.changeset(delegate, %{is_active: true})
      Vae.Repo.update(changeset)
    end
    
    Vae.Repo.all(Vae.Delegate)
    |> Enum.map(visibility_true)
  end
end
