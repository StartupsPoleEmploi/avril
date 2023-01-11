defmodule Vae.Certifier do
  use VaeWeb, :model

  alias __MODULE__
  alias Vae.{Certification, Delegate}

  schema "certifiers" do
    field(:slug, :string)
    field(:name, :string)
    field(:siret, :string)
    field(:internal_notes, :string)
    field(:external_notes, :string)

    many_to_many(
      :certifications,
      Certification,
      join_through: "certifier_certifications",
      on_delete: :delete_all,
      on_replace: :delete
    )

    many_to_many(
      :active_certifications,
      Certification,
      join_through: "certifier_certifications",
      where: [is_active: true]
    )

    many_to_many(
      :delegates,
      Delegate,
      join_through: "certifiers_delegates",
      on_delete: :delete_all,
      on_replace: :delete
    )

    many_to_many(
      :active_delegates,
      Delegate,
      join_through: "certifiers_delegates",
      where: [is_active: true]
    )

    timestamps()
  end

  @educ_nat_id 2
  @army_ministry_id 17

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :siret, :internal_notes, :external_notes])
    |> slugify()
    |> validate_required([:name, :slug])
    |> unique_constraint([:slug, :siret])
    |> put_param_assoc(:delegates, params)
  end

  def to_slug(certifier) do
    Vae.String.parameterize(certifier.name)
  end

  def slugify(changeset) do
    put_change(changeset, :slug, to_slug(Map.merge(changeset.data, changeset.changes)))
  end

  def is_educ_nat?(%Certifier{id: @educ_nat_id}), do: true
  def is_educ_nat?(_), do: false

  def is_army_ministry?(%Certifier{id: @army_ministry_id}), do: true
  def is_army_ministry?(_), do: false

  def merge_into(%Certifier{slug: slug_to_keep, siret: siret_to_keep} = certifier_to_keep, %Certifier{slug: slug_to_remove, siret: siret_to_remove} = certifier_to_remove) do
    %Certifier{certifications: certifications, delegates: delegates} =  certifier_to_remove
    |> Repo.preload([certifications: :certifiers, delegates: :certifiers])

    Enum.map(certifications, fn %Certification{certifiers: certifiers} = c ->
      new_certifiers = (certifiers ++ [certifier_to_keep]) |> Enum.reject(&(&1.slug == slug_to_remove))
      Certification.changeset(c, %{certifiers: new_certifiers}) |> Repo.update()
    end)

    Enum.map(delegates, fn %Delegate{certifiers: certifiers} = d ->
      new_certifiers = (certifiers ++ [certifier_to_keep]) |> Enum.reject(&(&1.slug == slug_to_remove))
      Delegate.changeset(d, %{certifiers: new_certifiers}) |> Repo.update()
    end)

    Repo.delete(certifier_to_remove)

    Certifier.changeset(certifier_to_keep, %{siret: siret_to_keep || siret_to_remove}) |> Repo.update()
  end

  defimpl Phoenix.Param, for: Vae.Certifier do
    def to_param(%{id: id, slug: slug}) do
      "#{id}-#{slug}"
    end
  end
end
