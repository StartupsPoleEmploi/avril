defmodule Vae.UserApplication do
  require Logger

  use VaeWeb, :model

  alias Vae.{
    Certifier,
    Certification,
    Delegate,
    Meeting,
    Repo,
    Resume,
    User
  }

  alias __MODULE__

  schema "applications" do
    field(:submitted_at, :utc_datetime)
    field(:delegate_access_refreshed_at, :utc_datetime)
    field(:delegate_access_hash, :string)
    field(:admissible_at, :utc_datetime)
    field(:inadmissible_at, :utc_datetime)
    field(:booklet_hash, :string)

    belongs_to(:user, User, foreign_key: :user_id)
    belongs_to(:delegate, Delegate, foreign_key: :delegate_id, on_replace: :nilify)
    belongs_to(:certification, Certification, foreign_key: :certification_id)
    belongs_to(:meeting, Meeting, foreign_key: :meeting_id, where: [deleted_at: nil])

    has_many(:resumes, Resume, on_delete: :delete_all, foreign_key: :application_id)

    has_many(
      :certifiers,
      through: [:certification, :certifiers]
    )

    embeds_one(:booklet_1, Vae.Booklet.Cerfa, on_replace: :delete)

    timestamps()
  end

  @fields ~w(user_id delegate_id certification_id submitted_at delegate_access_refreshed_at delegate_access_hash)a

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
    |> init_booklet_hash()
  end

  def attach_delegate_changeset(struct, %Delegate{} = delegate) do
    struct
    |> change(%{
      submitted_at: nil,
      delegate_access_hash: nil,
      delegate_access_refreshed_at: nil,
      meeting: nil
    })
    |> put_assoc(:delegate, delegate)
  end

  def attach_resume_changeset(struct, resume_file) do
    resume = Resume.attach_resume_to_application(struct, resume_file)
    struct
    |> change()
    |> put_assoc(:resumes, [resume | struct.resumes])
  end

  def register_meeting_changeset(struct, meeting) do
    struct
    |> change()
    |> put_assoc(:meeting, meeting)
  end

  def init_booklet_hash(changeset) do
    change(changeset, booklet_hash: changeset.data.booklet_hash || generate_hash(64))
  end

  def delete_with_resumes(%UserApplication{} = ua) do
    %UserApplication{resumes: resumes} = ua |> Repo.preload(:resumes)

    Enum.reduce(resumes, {:ok, nil}, fn resume, {:ok, _} ->
      Resume.delete(resume)
    end)
    |> case do
      {:ok, _} -> Repo.delete(ua)
      error -> error
    end
  end

  def find_or_create_with_params(%{user_id: user_id, certification_id: certification_id} = params)
      when not is_nil(user_id) and not is_nil(certification_id) do
    case Repo.get_by(UserApplication, user_id: user_id, certification_id: certification_id) do
      nil -> %UserApplication{} |> changeset(params) |> Repo.insert()
      a -> {:ok, a}
    end
  end

  def find_or_create_with_params(_params) do
    {:ok, nil}
  end

  def set_delegate(%UserApplication{} = application, %Delegate{id: id} = _delegate) do
    application
    |> change(%{delegate_id: id})
    |> Repo.update()
  end

  def generate_delegate_access_hash_changeset(application) do
    change(application, %{
      delegate_access_hash: generate_hash(64),
      delegate_access_refreshed_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })
  end

  def meeting_submitted_at_changeset(application) do
    change(application, %{
      submitted_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })
  end

  def list_from_last_month(%Date{} = end_date) do
    start_date = Vae.Date.get_previous_month(end_date)

    from(a in __MODULE__,
      where: fragment("(?)::timestamp::date", a.submitted_at) == ^start_date,
      preload: [user: [:job_seeker], delegate: [:certifiers]]
    )
    |> Repo.all()
  end

  def submitted_now(application) do
    application
    |> change(%{submitted_at: DateTime.truncate(DateTime.utc_now(), :second)})
    |> Repo.update!()
  end

  def submitted_now_changeset(application) do
    change(application, %{submitted_at: DateTime.truncate(DateTime.utc_now(), :second)})
  end

  def admissible_now(application) do
    application
    |> change(admissible_at: DateTime.truncate(DateTime.utc_now(), :second))
    |> Repo.update!()
  end

  def inadmissible_now(application) do
    application
    |> change(inadmissible_at: DateTime.truncate(DateTime.utc_now(), :second))
    |> Repo.update!()
  end

  def save_booklet(application, booklet) do
    application
    |> change()
    |> put_embed(
      :booklet_1,
      Vae.Booklet.Cerfa.changeset(
        application.booklet_1 || %Vae.Booklet.Cerfa{},
        booklet
      )
    )
  end

  def from_application_id_and_user_id(application_id, user_id) do
    from(
      a in __MODULE__,
      join: c in Certification,
      on: a.certification_id == c.id,
      # join: d in Delegate,
      # on: a.delegate_id == d.id,
      where: a.id == ^application_id and a.user_id == ^user_id,
      preload: [certification: c]
    )
    |> Repo.one()
  end

  def reset_booklet(application) do
    application
    |> change()
    |> put_embed(:booklet_1, nil)
    |> Repo.update()
  end

  def certifier(%UserApplication{} = application) do
    with(
      %UserApplication{
        delegate: %Delegate{certifiers: delegate_certifiers},
        certification: %Certification{certifiers: certification_certifiers}
      } <- application |> Repo.preload([delegate: :certifiers, certification: :certifiers])
    ) do
      Enum.find(delegate_certifiers, &Enum.member?(certification_certifiers, &1))
    else
      _ -> nil
    end
  end

  def certifier_name(%UserApplication{} = application) do
    case certifier(application) do
      %Certifier{name: name} -> name
      _ -> nil
    end
  end

  def slug(%UserApplication{} = application) do
    application = Repo.preload(application, :certification)
    certification_slug = case application.certification do
      %Certification{slug: slug} when not is_nil(slug) -> slug
      _ -> nil
    end
    [application.id, certification_slug]
    |> Enum.filter(&(not is_nil(&1)))
    |> Enum.join("-")
  end

  def booklet_url(endpoint, application, opts \\ []) do
    application = application |> Repo.preload(:delegate)

    cond do
      application.delegate && Delegate.is_asp?(application.delegate) ->
        "https://vaedem.asp-public.fr/vaedem/creationCompte.html"

      true ->
        booklet_url!(endpoint, application, opts)
    end
  end

  def booklet_url!(endpoint, application, opts \\ []) do
    if is_nil(System.get_env("NUXT_BOOKLET_PATH")) do
      Logger.warn("NUXT_BOOKLET_PATH environment variables not set")
    end

    %URI{
      path: "#{System.get_env("NUXT_BOOKLET_PATH")}/#{slug(application)}#{opts[:path] || "/"}",
      query:
        if(opts[:delegate_mode],
          do: "delegate_hash=#{application.delegate_access_hash}"
        )
    }
    |> Vae.URI.to_absolute_string(endpoint)
  end

  defp generate_hash(length) do
    :crypto.strong_rand_bytes(length) |> Base.url_encode64() |> binary_part(0, length)
  end

  def merge_applications_with_unicity_constraint(list1, list2) do
    Enum.reduce(list1, list2, fn %UserApplication{user_id: user_id, certification_id: certification_id} = a1, result ->
      case Vae.Enum.reject_and_find(result, &(&1.user_id == user_id && &1.certification_id == certification_id)) do
        {result, nil} -> [a1 | result]
        {result, a2} -> [(if get_comparison_score(a1, a2) > 0, do: a1, else: a2) | result]
      end
    end)
  end

  def get_comparison_score(%UserApplication{} = a1, %UserApplication{} = a2) do
    a1 = Repo.preload(a1, :resumes)
    a2 = Repo.preload(a2, :resumes)
    [delegate_id: 3, inserted_at: 1, submitted_at: 20, meeting: 3, booklet_1: 2, resumes: 1]
    |> Enum.reduce(0, fn {k, v}, score ->
      case {k, Map.get(a1, k), Map.get(a2, k)} do
        {_, val, nil} when not is_nil(val) -> v
        {_, nil, val} when not is_nil(val) -> -v
        {:booklet_1, %Vae.Booklet.Cerfa{experiences: e1}, %Vae.Booklet.Cerfa{experiences: e2}} -> v * (length(e1) - length(e2))
        {:resumes, r1, r2} -> v * length(r1) - length(r2)
        {_, v1, v2} ->
          if Timex.Comparable.impl_for(v1) && Timex.Comparable.impl_for(v2) do
            if Timex.after?(v1, v2), do: 1, else: -1
          else
            0
          end
      end + score
    end)
  end

end
