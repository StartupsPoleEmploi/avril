defmodule Vae.Certification do
  use VaeWeb, :model

  alias __MODULE__
  alias Vae.{UserApplication, Certifier, Delegate, Repo, Rome}

  schema "certifications" do
    field(:is_active, :boolean)
    field(:slug, :string)
    field(:label, :string)
    field(:acronym, :string)
    field(:level, :integer)
    field(:rncp_id, :string)
    field(:activities, :string)
    field(:abilities, :string)
    field(:activity_area, :string)
    field(:accessible_job_type, :string)

    belongs_to(:newer_certification, Certification, foreign_key: :newer_certification_id)

    many_to_many(
      :certifiers,
      Certifier,
      join_through: "certifier_certifications",
      on_delete: :delete_all,
      on_replace: :delete
    )

    many_to_many(
      :romes,
      Rome,
      join_through: "rome_certifications",
      on_replace: :delete,
      on_delete: :delete_all
    )

    many_to_many(
      :delegates,
      Delegate,
      join_through: "certifications_delegates",
      on_replace: :delete,
      on_delete: :delete_all
    )

    has_many(
      :rncp_delegates,
      through: [:certifiers, :delegates]
    )

    has_many(
      :professions,
      through: [:romes, :professions]
    )

    has_many(:applications, UserApplication, on_replace: :nilify)

    has_many(
      :users,
      through: [:applications, :user]
    )

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :is_active,
      :label,
      :acronym,
      :level,
      :rncp_id,
      :activities,
      :abilities,
      :activity_area,
      :accessible_job_type
    ])
    |> slugify()
    |> validate_required([:label, :slug])
    |> unique_constraint(:slug)
    |> add_romes(params)
    |> add_certifiers(params)
    # |> add_delegates(params)
    |> add_newer_certification(params)
  end

  # def find_by_acronym_and_label(certification_label) do
  #   from(
  #     c in Certification,
  #     where: fragment("lower(acronym || ' ' || label)") == ^String.downcase(certification_label)
  #   )
  #   |> Repo.one()
  # end

  def add_romes(changeset, %{romes: romes}) do
    changeset
    |> put_assoc(:romes, romes)
  end
  def add_romes(changeset, %{rome_ids: rome_ids}) do
    changeset
    |> put_assoc(:romes, get_romes(rome_ids))
  end

  def add_romes(changeset, _no_romes_param), do: changeset

  def get_romes(rome_ids) do
    Rome
    |> where([r], r.id in ^rome_ids)
    |> Repo.all()
  end

  def add_certifiers(changeset, %{certifiers: certifiers}) do
    changeset
    |> put_assoc(:certifiers, certifiers)
  end

  def add_certifiers(changeset, %{certifier_ids: certifier_ids}) do
    add_certifiers(changeset, %{certifiers: get_certifiers(certifier_ids)})
  end

  def add_certifiers(changeset, _no_certifiers), do: changeset

  def get_certifiers(certifier_ids) do
    Certifier
    |> where([c], c.id in ^certifier_ids)
    |> Repo.all()
  end

  def add_delegates(%Ecto.Changeset{changes: %{certifiers: certifiers_changes}} = changeset, _params) do
    delegates =
      Enum.flat_map(certifiers_changes, fn
        %{action: :update, data: certifiers} ->
          %Certifier{delegates: delegates} = Repo.preload(certifiers, :delegates)
          delegates
        _ -> []
      end)

    put_assoc(changeset, :delegates, delegates)
  end

  def add_delegates(changeset, _no_delegates_param), do: changeset

  def get_delegates(delegates) do
    Delegate
    |> where([d], d.id in ^delegates)
    |> Repo.all()
  end

  def from_certifier(certifier_id) do
    from(c in Certification,
      join: cc in "certifier_certifications",
      on: c.id == cc.certification_id and cc.certifier_id == ^certifier_id,
      select: c
    )
  end

  def add_newer_certification(changeset, %{newer_certification: newer_certification}) do
    changeset
    |> put_assoc(:newer_certification, newer_certification)
  end

  def add_newer_certification(changeset, _params), do: changeset

  def from_rome(nil), do: nil

  def from_rome(rome) do
    from(c in Certification,
      join: r in assoc(c, :romes),
      where: r.code == ^rome
    )
    |> Repo.all()
  end

  def format_for_index(struct) do
    struct
    |> Map.take(__schema__(:fields))
    |> Map.drop([:inserted_at, :updated_at, :description])
  end

  def name(%Certification{acronym: acronym, label: label}) do
    [acronym, label] |> Enum.reject(&is_nil/1) |> Enum.join(" ")
  end

  def to_slug(%Certification{is_active: is_active} = certification) do
    Vae.String.parameterize("#{unless is_active, do: "ancien"} #{name(certification)}")
  end

  def slugify(changeset) do
    put_change(changeset, :slug, to_slug(Map.merge(changeset.data, changeset.changes)))
  end

  def get_popular(limit \\ 10) do
    query = from c in Certification, [
      join: a in UserApplication,
      on: c.id == a.certification_id,
      group_by: c.id,
      order_by: [desc: count(a.id)],
      limit: ^limit
    ]
    Repo.all(query)
  end

  defimpl Phoenix.Param, for: Vae.Certification do
    def to_param(%{id: id, slug: slug}) do
      "#{id}-#{slug}"
    end
  end
end
