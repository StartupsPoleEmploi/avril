defmodule Vae.Certification do
  require Logger

  use VaeWeb, :model

  alias __MODULE__
  alias Ecto.Changeset
  alias Vae.{UserApplication, Certifier, Delegate, Repo, Rome}

  schema "certifications" do
    field(:rncp_id, :string)
    field(:is_rncp_active, :boolean)
    field(:is_active, :boolean, default: true)
    field(:slug, :string)
    field(:acronym, :string)
    field(:label, :string)
    field(:level, :integer)
    field(:last_rncp_import_date, :date)
    field(:end_of_rncp_validity, :date)
    field(:activities, :string)
    field(:abilities, :string)
    field(:activity_area, :string)
    field(:accessible_job_type, :string)
    field(:external_notes, :string)
    field(:internal_notes, :string)


    belongs_to(:newer_certification, Certification, foreign_key: :newer_certification_id, on_replace: :nilify)
    has_one(:older_certification, Certification, foreign_key: :newer_certification_id, on_replace: :nilify, on_delete: :nilify_all)

    many_to_many(
      :certifiers,
      Certifier,
      join_through: "certifier_certifications",
      on_delete: :delete_all,
      on_replace: :delete
    )

    many_to_many(
      :certifiers_no_rncp,
      Certifier,
      join_through: "certifier_certifications",
      on_delete: :delete_all,
      on_replace: :delete,
      where: [rncp_sync: false]
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
      Delegate,
      join_through: "certifications_delegates_exclusions",
      on_delete: :delete_all,
      on_replace: :delete
    )

    # Manually included delegates in admin
    many_to_many(
      :included_delegates,
      Delegate,
      join_through: "certifications_delegates_inclusions",
      on_delete: :delete_all,
      on_replace: :delete
    )

    # Actual associations : delegates = rncp + included - excluded
    many_to_many(
      :delegates,
      Delegate,
      join_through: "certifications_delegates"
    )

    many_to_many(
      :active_delegates,
      Delegate,
      join_through: "certifications_delegates",
      where: [is_active: true]
    )

    has_many(
      :professions,
      through: [:romes, :professions]
    )

    has_many(:applications, UserApplication, on_replace: :nilify)
    has_many(:recent_applications, UserApplication, where: [submitted_at: {:fragment, "? > now() - interval '16 days'"}])
    has_many(:quarter_applications, UserApplication, where: [submitted_at: {:fragment, "? > now() - interval '3 months'"}])

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
    # rncp_id is mistakenly parsed as integer while a string is expected here
    params = case params[:rncp_id] do
      v when is_integer(v) -> Map.put(params, :rncp_id, Integer.to_string(v))
      _ -> params
    end

    struct
    |> Repo.preload([
      :applications,
      :certifiers,
      :delegates,
      :included_delegates,
      :excluded_delegates,
      :older_certification
    ])
    |> cast(params, [
      :is_active,
      :is_rncp_active,
      :label,
      :acronym,
      :level,
      :rncp_id,
      :last_rncp_import_date,
      :end_of_rncp_validity,
      :activities,
      :abilities,
      :activity_area,
      :accessible_job_type,
      :external_notes,
      :internal_notes
    ])
    |> sanitize_html_fields([:activities, :abilities, :activity_area, :accessible_job_type])
    |> add_army_acronym()
    |> add_default_acronym()
    |> remove_acronym_in_label()
    |> put_param_assoc(:older_certification, params)
    |> put_param_assoc(:newer_certification, params)
    |> put_param_assoc(:romes, params)
    |> put_param_assoc(:certifiers, params)
    |> put_param_assoc(:included_delegates, params)
    |> put_param_assoc(:excluded_delegates, params)
    |> move_applications_if_older_certification()
    |> slugify()
    |> validate_required([:label, :slug, :rncp_id])
    |> unique_constraint(:slug)
    |> unique_constraint(:rncp_id)
  end

  def searchable_query() do
    from(c in Certification,
      where: c.is_active and fragment("""
        EXISTS (
          SELECT null FROM delegates
          INNER JOIN certifications_delegates
          ON delegates.id = certifications_delegates.delegate_id
          WHERE delegates.is_active
          AND certifications_delegates.certification_id = ?
        )
      """, c.id)
    )
  end

  def refresh_materialized_view() do
    Repo.query("REFRESH MATERIALIZED VIEW certifications_delegates;", [], timeout: :infinity)
    Repo.query("REFRESH MATERIALIZED VIEW searchable_certifications;", [], timeout: :infinity)
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

  def is_asp?(%Certification{} = certification) do
    %Certification{delegates: delegates} = certification |> Repo.preload(:delegates)
      case delegates do
        [%Delegate{slug: "asp-" <> _}] -> true
        _ -> false
      end
  end

  def is_reva?(%Certification{internal_notes: internal_notes}) do
    String.contains?(internal_notes || "", "REVA")
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

  def move_applications_if_older_certification(%Ecto.Changeset{} = changeset) do
    if get_change(changeset, :older_certification) do
      %Certification{applications: older_applications} = get_field(changeset, :older_certification) |> Repo.preload(:applications)
      put_assoc(
        changeset,
        :applications,
        (
          get_field(changeset, :applications) ++
          Enum.filter(older_applications, &(is_nil(&1.submitted_at)))
        )
      )
    else
      changeset
    end
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

  def rncp_changeset(cert_infos, params \\ nil)

  def rncp_changeset(rncp_id, params) when is_binary(rncp_id) do
    rncp_changeset(
      Repo.get_by(Certification, rncp_id: rncp_id) || %Certification{rncp_id: rncp_id},
      params
    )
  end

  def rncp_changeset(%Certification{rncp_id: rncp_id} = certification, params) do
    params = params || (
      rncp_id
      |> Vae.Authorities.Rncp.Api.get()
      |> Vae.Authorities.Rncp.FicheHandler.api_fiche_to_certification_params()
    )

    certification
    |> Certification.changeset(params)
  end

  def rncp_update(changeset) do
    case changeset do
      %Ecto.Changeset{data: %Certification{id: id}, changes: %{certifiers: certifiers}} when is_list(certifiers) and not is_nil(id) ->
        new_certifiers = Ecto.Changeset.fetch_field!(changeset, :certifiers)
        Logger.warn("Not updating certification ##{Ecto.Changeset.fetch_field!(changeset, :id)}: certifiers change: #{Enum.map(new_certifiers, &(&1.slug)) |> Enum.join(", ")}")
        {:ok, {changeset.data, new_certifiers}}
      changeset -> rncp_update!(changeset)
    end
  end

  def rncp_update!(changeset) do
    changeset
    |> change(%{last_rncp_import_date: Timex.today()})
    |> Repo.insert_or_update()
  end

  def transfert_old_applications_to_newer_certification() do
    from(
      c in Certification,
      where: not is_nil(c.newer_certification_id) and not c.is_rncp_active,
      preload: [:applications]
    )
    |> Repo.all()
    |> Enum.filter(fn %Certification{applications: applications} -> length(applications) > 0 end)
    |> Enum.each(fn %Certification{
      id: id,
      newer_certification_id: newer_certification_id
    } ->
      from(u in UserApplication, where: u.certification_id == ^id)
      |> Repo.update_all(set: [certification_id: newer_certification_id])
    end)
  end

  def fake_certification() do
    Repo.get_by(Certification, rncp_id: "0")
  end

  defimpl Phoenix.Param, for: Vae.Certification do
    def to_param(%{id: id, slug: slug}) do
      "#{id}-#{slug}"
    end
  end
end
