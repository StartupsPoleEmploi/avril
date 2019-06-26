defmodule Vae.Certification do
  use Vae.Web, :model

  alias __MODULE__
  alias Vae.{Application, CertificationDelegate, Certifier, Delegate, Repo, Rome}

  schema "certifications" do
    field(:slug, :string)
    field(:label, :string)
    field(:acronym, :string)
    field(:level, :integer)
    field(:rncp_id, :string)
    field(:description, :string)

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

    has_many(
      :certifications_delegates,
      CertificationDelegate,
      on_delete: :delete_all,
      on_replace: :delete
    )

    has_many(
      :delegates,
      through: [:certifications_delegates, :delegate]
    )

    # TODO: add many_to_manys
    has_many(:applications, Application, on_replace: :nilify)

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
    |> cast(params |> Map.update(:rncp_id, nil, fn e -> to_string(e) end), [
      :label,
      :acronym,
      :level,
      :rncp_id,
      :description
    ])
    |> slugify()
    |> validate_required([:label, :slug])
    |> add_romes(params)
    |> add_certifiers(params)
    |> add_delegates(params)
  end

  def get(nil), do: nil
  def get(id), do: Repo.get(Certification, id)

  def get_certification(%{"rncp_id" => rncp_id}), do: Repo.get_by(Certification, rncp_id: rncp_id)

  def get_certification(nil), do: nil

  def get_certification(certification_id), do: Repo.get(Certification, certification_id)

  def find_by_acronym_and_label(certification_label) do
    from(
      c in Certification,
      where: fragment("lower(acronym || ' ' || label)") == ^String.downcase(certification_label)
    )
    |> Repo.one()
  end

  def add_romes(changeset, %{romes: romes}) do
    changeset
    |> put_assoc(:romes, get_romes(romes))
  end

  def add_romes(changeset, _no_romes_param), do: changeset

  def get_romes(romes) do
    Rome
    |> where([r], r.id in ^romes)
    |> Repo.all()
  end

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

  def add_delegates(%Ecto.Changeset{changes: %{certifiers: certifiers}} = changeset, _params) do
    certifications_delegates =
      Enum.reduce(certifiers, [], fn
        %{action: :update, data: data}, acc ->
          [
            Delegate.from_certifier(data.id)
            |> Repo.all()
            |> Enum.map(fn delegate ->
              Ecto.build_assoc(changeset.data, :certifications_delegates, delegate_id: delegate.id)
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

  def add_delegates(changeset, %{certifications_delegates: certifications_delegates}) do
    changeset
    |> put_assoc(
      :certifications_delegates,
      certifications_delegates
      |> ensure_not_nil
      |> transform_destroy
      |> Enum.uniq_by(& &1.delegate_id)
    )
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

  def from_rome(nil), do: nil

  def from_rome(rome) do
    from(c in Certification,
      join: r in assoc(c, :romes),
      where: r.code == ^rome
    )
    |> Repo.all()
  end

  defp ensure_not_nil(certifications_delegates) do
    certifications_delegates
    |> Enum.filter(fn {_index, %{delegate_id: d_id}} -> d_id != nil end)
  end

  defp transform_destroy(collection_with_destroy) do
    collection_with_destroy
    |> Enum.reduce([], fn {_index, d}, acc ->
      case d[:_destroy] do
        "0" -> [d | acc]
        _ -> acc
      end
    end)
  end

  def format_for_index(struct) do
    struct
    |> Map.take(__schema__(:fields))
    |> Map.drop([:inserted_at, :updated_at, :description])
  end

  def name(certification), do: "#{certification.acronym} #{certification.label}"

  def to_slug(certification) do
    Vae.String.parameterize(__MODULE__.name(certification))
  end

  def slugify(changeset) do
    put_change(changeset, :slug, to_slug(Map.merge(changeset.data, changeset.changes)))
  end

  defimpl Phoenix.Param, for: Vae.Certification do
    def to_param(%{id: id, slug: slug}) do
      "#{id}-#{slug}"
    end
  end
end
