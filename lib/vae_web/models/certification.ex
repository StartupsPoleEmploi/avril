defmodule Vae.Certification do
  use VaeWeb, :model

  alias __MODULE__
  alias Ecto.Changeset
  alias Vae.{UserApplication, Certifier, Delegate, Repo, Rome}

  schema "certifications" do
    field(:rncp_id, :string)
    field(:is_active, :boolean)
    field(:slug, :string)
    field(:acronym, :string)
    field(:label, :string)
    field(:level, :integer)
    belongs_to(:newer_certification, Certification, foreign_key: :newer_certification_id)
    field(:activities, :string)
    field(:abilities, :string)
    field(:activity_area, :string)
    field(:accessible_job_type, :string)


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

    # Theoretical delegates
    has_many(
      :rncp_delegates,
      through: [:certifiers, :delegates]
    )

    # Manually excluded delegates in admin
    many_to_many(
      :excluded_delegates,
      Certification,
      join_through: "certifications_delegates_exclusions",
      on_delete: :delete_all,
      on_replace: :delete
    )

    # Manually included delegates in admin
    many_to_many(
      :included_delegates,
      Certification,
      join_through: "certifications_delegates_inclusions",
      on_delete: :delete_all,
      on_replace: :delete
    )

    # Actual associations : delegates = rncp + included - excluded
    many_to_many(
      :delegates,
      Delegate,
      join_through: "certifications_delegates",
      on_replace: :delete,
      on_delete: :delete_all
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
    |> Repo.preload([:certifiers, :delegates, :included_delegates, :excluded_delegates])
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
    |> add_army_acronym()
    |> slugify()
    |> validate_required([:label, :slug, :rncp_id])
    |> unique_constraint(:slug)
    |> unique_constraint(:rncp_id)
    |> add_newer_certification(params)
    |> add_romes(params)
    |> add_certifiers(params)
    |> add_included_excluded_delegates(params)
    |> link_delegates()
    |> make_inactive_if_no_delegates()
    # |> add_delegates(params)
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

  def add_included_excluded_delegates(changeset, %{
      included_delegate_ids: included_delegate_ids,
      excluded_delegate_ids: excluded_delegate_ids
    }) when is_list(included_delegate_ids) and is_list(excluded_delegate_ids) do
    included_delegates = Repo.all(from c in Certification, where: c.id in ^included_delegate_ids)
    excluded_delegates = Repo.all(from c in Certification, where: c.id in ^excluded_delegate_ids)

    changeset
    |> put_assoc(:included_delegates, included_delegates)
    |> put_assoc(:excluded_delegates, excluded_delegates)
  end
  def add_included_excluded_delegates(changeset, _), do: changeset

  def link_delegates(%Changeset{} = changeset) do
    if get_change(changeset, :certifiers) ||
       get_change(changeset, :included_delegates) ||
       get_change(changeset, :excluded_delegates) do

      certifiers = get_field(changeset, :certifiers) |> Repo.preload(:delegates)
      rncp_delegates = Enum.flat_map(certifiers, &(&1.delegates))

      delegates = Enum.uniq(rncp_delegates ++ get_field(changeset, :included_delegates) -- get_field(changeset, :excluded_delegates))

      changeset
      |> put_assoc(:delegates, delegates)
    else
      changeset
    end
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

  def add_army_acronym(%Changeset{} = changeset) do
    case get_field(changeset, :certifiers) |> Enum.find(&Certifier.is_army_ministry?(&1)) do
      %Certifier{name: name} ->
        changeset
        |> put_change(:acronym, "Diplôme #{name}" )
      _ -> changeset
    end
  end

  def make_inactive_if_no_delegates(%Ecto.Changeset{} = changeset) do
    unless List.first(get_field(changeset, :delegates)), do: put_change(changeset, :is_active, false), else: changeset
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
