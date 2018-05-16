defmodule Vae.Delegate do
  use Vae.Web, :model

  alias Ecto.Changeset

  alias Vae.Certification
  alias Vae.AlgoliaPlaces

  schema "delegates" do
    field(:name, :string)
    field(:website, :string)
    field(:address, :string)
    field(:telephone, :string)
    field(:email, :string)
    field(:person_name, :string)
    field(:is_active, :boolean, default: false)
    field(:geolocation, :map)
    field(:city, :string)
    field(:administrative, :string)

    belongs_to(:certifier, Vae.Certifier)
    belongs_to(:process, Vae.Process)

    has_many(
      :certifications_delegates,
      Vae.CertificationDelegate,
      on_delete: :delete_all,
      on_replace: :delete
    )

    has_many(:certifications, through: [:certifications_delegates, :certification])

    many_to_many(
      :steps,
      Vae.Step,
      join_through: "delegate_steps",
      on_delete: :delete_all
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
    struct
    |> cast(params, [
      :name,
      :website,
      :address,
      :telephone,
      :email,
      :person_name,
      :is_active,
      :geolocation,
      :city,
      :administrative
    ])
    |> validate_required([:name])
  end

  def changeset_update(struct, params) do
    params =
      Map.merge(
        params,
        case params[:is_active] do
          "true" -> %{is_active: true}
          _ -> %{is_active: false}
        end
      )

    # TODO: index after putting it to DB (not a changeset)
    struct
    |> change(params)
    |> link_certifications()
    |> geocode_address()
  end

  defp geocode_address(changeset) do
    case changeset do
      %{changes: %{address: address}} ->
        geolocation = AlgoliaPlaces.get_first_hit_to_index(address)

        changeset
        |> put_change(:city, AlgoliaPlaces.get_city(geolocation))
        |> put_change(:administrative, AlgoliaPlaces.get_administrative(geolocation))
        |> put_change(:geolocation, geolocation)

      _ ->
        changeset
    end
  end

  def link_certifications(%Changeset{changes: %{certifier_id: certifier_id}} = changeset) do
    certifications_delegates =
      certifier_id
      |> Certification.get_certifications_by_certifier()
      |> Enum.map(&%{certification_id: &1.id})

    changeset
    |> put_assoc(:certifications_delegates, certifications_delegates)
  end

  def link_certifications(changeset), do: changeset

  def add_process(delegate, process) do
    delegate
    |> change
    |> put_assoc(:process, process)
  end

  def add_certifications(delegate, certifications) do
    delegate
    |> change
    |> put_assoc(:certifications, certifications)
  end
end
