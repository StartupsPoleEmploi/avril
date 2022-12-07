defmodule Vae.Delegate do
  use VaeWeb, :model

  alias __MODULE__
  alias Vae.{
    UserApplication,
    Certification,
    Certifier,
    Places.Ban,
    Repo
  }

  schema "delegates" do
    field(:is_active, :boolean, default: false)
    field(:is_prc, :boolean, default: false)
    field(:has_mandatory_booklet, :boolean, default: false)
    field(:slug, :string)
    field(:name, :string)
    field(:academy_id, :string)
    field(:website, :string)
    field(:address_name, :string)
    field(:address, :string)
    field(:telephone, :string)
    field(:email, :string)
    field(:person_name, :string)
    field(:secondary_email, :string)
    field(:secondary_person_name, :string)
    field(:geom, Geo.PostGIS.Geometry)
    field(:city, :string)
    field(:administrative, :string)
    field(:internal_notes, :string)
    field(:external_notes, :string)

    many_to_many(
      :certifiers,
      Certifier,
      join_through: "certifiers_delegates",
      on_delete: :delete_all,
      on_replace: :delete
    )

    # Theoretical certifications
    has_many(
      :rncp_certifications,
      through: [:certifiers, :active_certifications]
    )

    # Manually excluded certifications in admin
    many_to_many(
      :excluded_certifications,
      Certification,
      join_through: "certifications_delegates_exclusions",
      on_delete: :delete_all,
      on_replace: :delete
    )

    # Manually included certifications in admin
    many_to_many(
      :included_certifications,
      Certification,
      join_through: "certifications_delegates_inclusions",
      on_delete: :delete_all,
      on_replace: :delete
    )

    # Actual associations : certifications = rncp + included - excluded
    many_to_many(
      :certifications,
      Certification,
      join_through: "certifications_delegates"
    )

    many_to_many(
      :active_certifications,
      Certification,
      join_through: "certifications_delegates",
      where: [is_active: true]
    )

    has_many(:applications, UserApplication)
    has_many(:recent_applications, UserApplication, where: [submitted_at: {:fragment, "? > now() - interval '16 days'"}])
    has_many(:quarter_applications, UserApplication, where: [submitted_at: {:fragment, "? > now() - interval '3 months'"}])

    has_many(
      :users,
      through: [:applications, :user]
    )

    timestamps()
  end

  def from_certification(certification) do
    from(d in assoc(certification, :delegates))
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do

    params = Vae.Map.transform_if_present(params, [
      {:academy_id, &Integer.to_string(&1)}, # academy_id is mistakenly parsed as integer while a string is expected here
      {:email, &Vae.String.sanitize_email(&1)},
      {:secondary_email, &Vae.String.sanitize_email(&1)},
    ])

    struct
    |> Repo.preload([
      :certifiers,
      :certifications,
      :included_certifications,
      :excluded_certifications
    ])
    |> cast(params, [
      :name,
      :website,
      :address_name,
      :address,
      :telephone,
      :email,
      :person_name,
      :secondary_email,
      :secondary_person_name,
      :is_active,
      :is_prc,
      :has_mandatory_booklet,
      :geom,
      :city,
      :administrative,
      :academy_id,
      :internal_notes,
      :external_notes
    ])
    |> slugify()
    |> make_inactive_if_email_missing()
    |> validate_required([:name, :slug])
    |> unique_constraint(:slug)
    |> validate_format(:email, ~r/@/)
    |> validate_format(:secondary_email, ~r/@/)
    |> add_geolocation()
    |> put_param_assoc(:certifiers, params)
    |> put_param_assoc(:included_certifications, params)
    |> put_param_assoc(:excluded_certifications, params)
  end

  defp add_geolocation(%Ecto.Changeset{changes: %{address: _}} = changeset) do
    result = Ban.get_geoloc_from_address(get_field(changeset, :address))
    changeset
    |> put_change(:city, Ban.get_field(result, :city))
    |> put_change(:administrative, Ban.get_field(result, :administrative))
    |> put_change(:geom, %Geo.Point{coordinates: Ban.get_field(result, :lng_lat)})
  end

  defp add_geolocation(changeset), do: changeset

  def slugify(%Ecto.Changeset{data: data, changes: changes} = changeset) do
    put_change(changeset, :slug, to_slug(Map.merge(data, changes)))
  end

  def make_inactive_if_email_missing(%Ecto.Changeset{} = changeset) do
    if is_nil(get_field(changeset, :email)), do: put_change(changeset, :is_active, false), else: changeset
  end

  def get_meeting_source(%Delegate{academy_id: academy_id}) when not is_nil(academy_id), do: :france_vae
  def get_meeting_source(%Delegate{name: "AFPA" <> _rest}), do: :afpa
  def get_meeting_source(%Delegate{}), do: nil

  def is_asp?(%Delegate{name: name}) do
    String.starts_with?(name, "ASP")
  end

  def is_afpa?(%Delegate{name: name}) do
    String.starts_with?(name, "AFPA")
  end

  def is_educ_nat?(%Delegate{} = delegate) do
    delegate
    |> Repo.preload(:certifiers)
    |> Map.get(:certifiers)
    |> Enum.any?(&Certifier.is_educ_nat?/1)
  end

  def is_corse?(%Delegate{administrative: "Corse"}), do: true
  def is_corse?(_), do: false

  def external_subscription_link(%Delegate{} = delegate) do
    if delegate.academy_id do
      Vae.Meetings.FranceVae.Config.get_france_vae_academy_page(delegate.academy_id)
    else
      # This case should not happen after academy_ids are set
      if is_educ_nat?(delegate) && !is_corse?(delegate) do
        Vae.Meetings.FranceVae.Config.get_domain_name()
      end
    end
  end

  def to_slug(%Delegate{} = delegate) do
    Vae.String.parameterize(
      "#{delegate.name} #{
        if delegate.city && delegate.name =~ delegate.city, do: "", else: delegate.city
      } #{
        if delegate.administrative && delegate.name =~ delegate.administrative,
          do: "",
          else: delegate.administrative
      }"
    )
  end

  def merge([delegate_id | _rest] = delegate_ids) when is_integer(delegate_id) do
    delegate_ids
    |> Enum.map(&Repo.get(Delegate, &1))
    |> merge()
  end

  def merge([%Delegate{} = delegate | other_delegates] = delegates) do
    delegates = delegates |> Repo.preload([:applications, :certifiers])

    merged_fields = Delegate.__schema__(:fields)
    |> Enum.reject(fn f -> f in [:id, :slug, :is_active, :inserted_at, :updated_at] end)
    |> Enum.reduce(%{}, fn field, acc ->
      Map.put(acc, field, Enum.find_value(delegates, fn d -> Map.get(d, field) end))
    end)

    delegate
    |> changeset(Map.merge(merged_fields, %{
      applications: Enum.flat_map(delegates, &(&1.applications)),
      certifiers: Enum.flat_map(delegates, &(&1.certifiers))
    }))
    |> Repo.update()

    other_delegates |> Enum.each(&Repo.delete(&1))
  end

  def website(%Delegate{website: website}) do
    case website do
      "http://" <> _rest -> website
      "https://" <> _rest -> website
      _other -> "http://#{website}"
    end
    |> String.trim()
  end

  def users(%Delegate{email: email, secondary_email: secondary_email}) do
    Repo.all(
      from u in Vae.User,
      where: (u.email in ^[email, secondary_email])
    )
  end

  def users(_), do: []


  defimpl Phoenix.Param, for: Vae.Delegate do
    def to_param(%{id: id, slug: slug}) do
      "#{id}-#{slug}"
    end
  end
end
