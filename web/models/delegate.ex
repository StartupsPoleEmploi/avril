defmodule Vae.Delegate do
  use Vae.Web, :model
  alias Vae.Repo.NewRelic, as: Repo

  alias Ecto.Changeset

  alias __MODULE__
  alias Vae.{Certification, CertificationDelegate, Certifier, Process, Application}
  alias Vae.Places

  schema "delegates" do
    field(:slug, :string)
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

    belongs_to(:process, Process)

    has_many(
      :certifications_delegates,
      CertificationDelegate,
      on_delete: :delete_all,
      on_replace: :delete
    )

    has_many(:certifications, through: [:certifications_delegates, :certification])

    has_many(:applications, Application, on_replace: :nilify) # TODO: add many_to_manys

    has_many(
      :users,
      through: [:applications, :user]
    )

    many_to_many(
      :certifiers,
      Certifier,
      join_through: "certifiers_delegates",
      on_delete: :delete_all,
      on_replace: :delete
    )

    timestamps()
  end

  def from_certification(certification) do
    from(d in assoc(certification, :delegates))
  end

  def from_certifier(certifier_id) do
    from(d in Delegate,
      join: cd in "certifiers_delegates",
      on: d.id == cd.delegate_id and cd.certifier_id == ^certifier_id,
      select: d
    )
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
    |> slugify
    |> validate_required([:name, :slug])
    |> add_certifiers(params)
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

    struct
    |> Repo.preload([:certifiers, :certifications_delegates])
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
      :administrative,
      :process_id
    ])
    |> add_certifiers(params)
    |> link_certifications()
    |> add_geolocation(params)
  end

  def get(nil), do: nil
  def get(id), do: Repo.get(Delegate, id)

  def add_certifiers(changeset, %{certifiers: certifiers}) do
    changeset
    |> put_assoc(:certifiers, get_certifiers(certifiers))
  end

  def add_certifiers(changeset, _no_certifiers), do: changeset

  def get_certifiers(certifiers) do
    Certifier
    |> where([c], c.id in ^certifiers)
    |> Repo.all()
  end

  def link_certifications(%Changeset{changes: %{certifiers: certifiers}} = changeset) do
    certifications_delegates =
      Enum.reduce(certifiers, [], fn
        %{action: :update, data: data}, acc ->
          [
            Certification.from_certifier(data.id)
            |> Repo.all()
            |> Enum.map(fn certification ->
              Ecto.build_assoc(changeset.data, :certifications_delegates,
                certification_id: certification.id
              )
            end)
            | acc
          ]

        _, acc ->
          acc
      end)

    put_assoc(
      changeset,
      :certifications_delegates,
      List.flatten(certifications_delegates)
    )
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

  defp add_geolocation(%{changes: %{address: _}} = changeset, %{geo: encoded})
       when not is_nil(encoded) do
    geolocation = Poison.decode!(encoded)

    changeset
    |> put_change(:city, Places.get_city(geolocation))
    |> put_change(:administrative, Places.get_administrative(geolocation))
    |> put_change(:geolocation, geolocation)
  end

  defp add_geolocation(changeset, _params), do: changeset

  def format_for_index(nil), do: nil

  def format_for_index(%__MODULE__{} = delegate) do
    delegate = delegate |> Repo.preload(:certifiers)

    certifiers =
      Enum.reduce(delegate.certifiers, [], fn certifier, acc ->
        [certifier.id | acc]
      end)

    delegate
    |> Map.take(Delegate.__schema__(:fields))
    |> Map.put(:certifiers, certifiers)
    |> Map.put(:_geoloc, delegate.geolocation["_geoloc"])
  end

  def is_asp?(%__MODULE__{} = delegate) do
    String.starts_with?(delegate.name, "ASP")
  end

  def is_educ_nat?(%__MODULE__{} = delegate) do
    delegate
    |> Repo.preload(:certifiers)
    |> Map.get(:certifiers)
    |> Enum.reduce(false, fn certifier, result -> result || Certifier.is_educ_nat?(certifier) end)
  end

  def is_corse?(%__MODULE__{} = delegate) do
    delegate.administrative == "Corse"
  end

  def external_subscription_link(%__MODULE__{} = delegate) do
    delegate = Repo.preload(delegate, :process)
    if __MODULE__.is_educ_nat?(delegate) && !__MODULE__.is_corse?(delegate), do: delegate.process.booklet_1 || "https://www.francevae.fr"
  end

  def to_slug(%__MODULE__{} = delegate) do
    Vae.String.parameterize("#{delegate.name} #{if (delegate.city && delegate.name =~ delegate.city), do: "", else: delegate.city} #{if (delegate.administrative && delegate.name =~ delegate.administrative), do: "", else: delegate.administrative}")
  end

  def slugify(changeset) do
    put_change(changeset, :slug, to_slug(Map.merge(changeset.data, changeset.changes)))
  end

  defimpl Phoenix.Param, for: Vae.Delegate do
    def to_param(%{id: id, slug: slug}) do
      "#{id}-#{slug}"
    end
  end
end
