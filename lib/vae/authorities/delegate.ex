defmodule Vae.Delegate do
  use VaeWeb, :model

  alias __MODULE__
  alias Ecto.Changeset
  alias Vae.{
    UserApplication,
    Certification,
    CertificationDelegate,
    Certifier,
    Meeting,
    Places,
    Process,
    Repo
  }

  schema "delegates" do
    field(:slug, :string)
    field(:name, :string)
    field(:academy_id, :string)
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

    has_many(:applications, UserApplication, on_replace: :nilify)
    has_many(:recent_applications, UserApplication, where: [inserted_at: {:fragment, "? > now() - interval '16 days'"}, submitted_at: {:not, nil}])

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

    embeds_many(:meeting_places, Vae.MeetingPlace, on_replace: :delete)

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
      :administrative,
      :academy_id
    ])
    |> slugify()
    |> validate_required([:name, :slug])
    |> unique_constraint(:slug)
    |> add_certifiers(params)
  end

  # TODO: consider refacto changeset and changeset_update, or remove one
  def changeset_update(struct, params) do
    params =
      Map.merge(
        params,
        case params[:is_active] do
          "true" -> %{is_active: true}
          _ -> %{is_active: false}
        end
      )
      |> Map.merge(
        case params[:academy_id] do
          nil -> %{}
          id -> %{academy_id: Integer.to_string(id)}
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
      :process_id,
      :academy_id
    ])
    |> slugify()
    |> validate_required([:name, :slug])
    |> unique_constraint(:slug)
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

  def put_meeting_places(delegate, meetings) do
    delegate
    |> change
    |> put_embed(:meeting_places, meetings)
  end

  defp add_geolocation(%{changes: %{address: _}} = changeset, %{geo: encoded})
       when not is_nil(encoded) do
    geolocation = Poison.decode!(encoded)

    changeset
    |> put_change(:city, Places.get_city(geolocation))
    |> put_change(:administrative, Places.get_administrative(geolocation))
    |> put_change(:geolocation, geolocation)
  end

  defp add_geolocation(
         changeset,
         %{geolocation: %{"city" => city, "administrative" => administrative}} = geolocation
       ) do
    changeset
    |> put_change(:city, List.first(city))
    |> put_change(:administrative, List.first(administrative))
    |> put_change(:geolocation, geolocation)
  end

  defp add_geolocation(changeset, _params), do: changeset

  def format_for_index(nil), do: nil

  def format_for_index(%Delegate{} = delegate) do
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

  def is_asp?(%Delegate{} = delegate) do
    String.starts_with?(delegate.name, "ASP")
  end

  def is_educ_nat?(%Delegate{} = delegate) do
    delegate
    |> Repo.preload(:certifiers)
    |> Map.get(:certifiers)
    |> Enum.reduce(false, fn certifier, result -> result || Certifier.is_educ_nat?(certifier) end)
  end

  def is_corse?(%Delegate{} = delegate) do
    delegate.administrative == "Corse"
  end

  def external_subscription_link(%Delegate{} = delegate) do
    if delegate.academy_id do
      Vae.Meetings.FranceVae.Config.get_france_vae_academy_page(delegate.academy_id)
    else
      # This case should not happen after academy_ids are set
      if is_educ_nat?(delegate) && !is_corse?(delegate) do
        Repo.preload(delegate, :process).process.booklet_1 ||
          Vae.Meetings.FranceVae.Config.get_domain_name()
      end
    end
  end

  def display_name(%Delegate{} = delegate), do: delegate.name

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

  def slugify(changeset) do
    put_change(changeset, :slug, to_slug(Map.merge(changeset.data, changeset.changes)))
  end

  def get_certifications(%Delegate{} = delegate) do
    delegate |> Repo.preload(:certifications) |> Map.get(:certifications)
  end

  def get_popular(limit \\ 10) do
    query =
      from(d in Delegate,
        join: a in UserApplication,
        on: d.id == a.delegate_id,
        group_by: d.id,
        order_by: [desc: count(a.id)],
        limit: ^limit
      )

    Repo.all(query)
  end

  defimpl Phoenix.Param, for: Vae.Delegate do
    def to_param(%{id: id, slug: slug}) do
      "#{id}-#{slug}"
    end
  end
end
