defmodule Vae.UserApplication do
  require Logger

  use VaeWeb, :model

  alias VaeWeb.ApplicationEmail
  alias VaeWeb.Mailer

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
    # Triggers an analytics event at the front
    field(:has_just_been_auto_submitted, :boolean, virtual: true)
    field(:submitted_at, :utc_datetime)
    field(:delegate_access_refreshed_at, :utc_datetime)
    field(:delegate_access_hash, :string)
    field(:admissible_at, :utc_datetime)
    field(:inadmissible_at, :utc_datetime)
    field(:booklet_hash, :string)

    belongs_to(:user, User, foreign_key: :user_id)
    belongs_to(:delegate, Delegate, foreign_key: :delegate_id, on_replace: :nilify)
    belongs_to(:certification, Certification, foreign_key: :certification_id)

    has_many(:resumes, Resume, on_delete: :delete_all, foreign_key: :application_id)

    has_many(
      :certifiers,
      through: [:certification, :certifiers]
    )

    embeds_one(:meeting, Meeting, on_replace: :delete)
    embeds_one(:booklet_1, Vae.Booklet.Cerfa, on_replace: :delete)

    timestamps()
  end

  @fields ~w(user_id delegate_id certification_id submitted_at delegate_access_refreshed_at delegate_access_hash has_just_been_auto_submitted)a

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
    |> init_booklet_hash()
  end

  def attach_delegate_changeset(struct, %Delegate{} = delegate) do
    struct
    |> change()
    |> put_assoc(:delegate, delegate)
  end

  def attach_resume_changeset(struct, resume_file) do
    resume = Resume.attach_resume_to_application(struct, resume_file)
    struct
    |> change()
    |> put_assoc(:resumes, [resume | struct.resumes])
  end

  def register_meeting_changeset(struct, params) do
    struct
    |> change()
    |> put_embed(:meeting, params)
  end

  def init_booklet_hash(changeset) do
    change(changeset, booklet_hash: changeset.data.booklet_hash || generate_hash(64))
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

  # Deprecated
  def submit(application, auto_submitted \\ false) do
    application = Repo.preload(application, [:user, :delegate])

    case User.submit_application_required_missing_fields(application.user) do
      [] ->
        if is_nil(application.submitted_at) do
          with(
            {:ok, application} <-
              Repo.update(
                __MODULE__.changeset(application, %{
                  delegate_access_hash: generate_hash(64),
                  delegate_access_refreshed_at: DateTime.utc_now()
                })
              ),
            {:ok, _messages} <-
              Mailer.send(
                if Delegate.is_asp?(application.delegate),
                  do: ApplicationEmail.asp_user_submission_confirmation(application),
                  else: [
                    ApplicationEmail.delegate_submission(application),
                    ApplicationEmail.user_submission_confirmation(application)
                  ]
              )
          ) do
            Repo.update(
              __MODULE__.changeset(application, %{
                has_just_been_auto_submitted: auto_submitted,
                submitted_at: DateTime.utc_now()
              })
            )
          else
            error -> error
          end
        else
          {:ok, application}
        end

      missing_fields ->
        {:error, "Remplissez d'abord les données manquantes : #{Enum.join(missing_fields, ", ")}"}
    end
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
end
