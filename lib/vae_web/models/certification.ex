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
      through: [:certifiers, :active_delegates]
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
    |> Repo.preload([
      :certifiers,
      :delegates,
      :included_delegates,
      :excluded_delegates
    ])
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
    |> sanitize_html_fields([:activities, :abilities, :activity_area, :accessible_job_type])
    |> add_army_acronym()
    |> remove_acronym_in_label()
    |> add_default_acronym()
    |> slugify()
    |> validate_required([:label, :slug, :rncp_id])
    |> unique_constraint(:slug)
    |> unique_constraint(:rncp_id)
    |> put_param_assoc(:newer_certification, params)
    |> put_param_assoc(:romes, params)
    |> put_param_assoc(:certifiers, params)
    |> put_param_assoc(:included_delegates, params)
    |> put_param_assoc(:excluded_delegates, params)
    |> link_delegates()
    |> make_inactive_if_no_delegates()
  end

  def link_delegates(changeset) do
    # if get_change(changeset, :certifiers) ||
    #    get_change(changeset, :included_delegates) ||
    #    get_change(changeset, :excluded_delegates) do

      # changeset = %Changeset{changeset | data: Repo.preload(changeset.data, :rncp_delegates)}

      # rncp_delegates = get_field(changeset, :rncp_delegates)
      rncp_delegates = get_field(changeset, :certifiers)
        |> Repo.preload(:active_delegates)
        |> Enum.flat_map(&(&1.active_delegates))

      included_delegates = get_field(changeset, :included_delegates)
      excluded_delegates = get_field(changeset, :excluded_delegates)

      delegates = Enum.uniq(rncp_delegates ++ included_delegates) -- excluded_delegates

      changeset
      |> put_assoc(:delegates, delegates)
    # else
    #   changeset
    # end
  end

  def format_for_index(struct) do
    struct
    |> Map.take(__schema__(:fields))
    |> Map.drop([
      :inserted_at,
      :updated_at,
      :activities,
      :abilities,
      :activity_area,
      :accessible_job_type
    ])
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
      %Certifier{name: name} -> put_change(changeset, :acronym, "Diplôme #{name}" )
      _ -> changeset
    end
  end

  def add_default_acronym(%Changeset{} = changeset) do
    if Vae.String.is_blank?(get_field(changeset, :acronym)) do
      put_change(changeset, :acronym, "Diplôme")
    else
      changeset
    end
  end

  def remove_acronym_in_label(%Changeset{} = changeset) do
    if String.starts_with?(get_field(changeset, :label), get_field(changeset, :acronym) || "") do
      put_change(changeset, :label, String.replace_prefix(get_field(changeset, :label), get_field(changeset, :acronym) || "", ""))
    else
      changeset
    end
  end

  def make_inactive_if_no_delegates(%Ecto.Changeset{} = changeset) do
    unless List.first(get_field(changeset, :delegates)), do: put_change(changeset, :is_active, false), else: changeset
  end

  def sanitize_html_fields(%Ecto.Changeset{} = changeset, fields) do
    Enum.reduce(fields, changeset, fn field, cs ->
      case get_field(cs, field) do
        str when is_binary(str) ->
          new_value = str
          |> String.replace(~r/<p>\s+<\/p>/iu, "")
          |> String.trim()
          put_change(cs, field, new_value)
        _ -> cs
      end
    end)
  end

  defimpl Phoenix.Param, for: Vae.Certification do
    def to_param(%{id: id, slug: slug}) do
      "#{id}-#{slug}"
    end
  end
end
