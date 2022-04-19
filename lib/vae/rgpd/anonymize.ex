defmodule Vae.Rgpd.Anonymize do
  import Ecto.Query
  alias Vae.{JobSeeker, User, UserApplication, Repo, Resume}

  @anonymous_mail_domain "@anonymous.com"

  def anonymize_all(field_name\\:updated_at) do

    Repo.transaction(fn ->
      users_query(field_name)
      |> Repo.stream()
      |> Stream.each(&anonymize(&1))
      |> Stream.run()
    end, timeout: :infinity)

    delete_job_seekers() |> IO.inspect()
  end

  def users_query(field_name\\:updated_at) do
    from(u in User)
    |> where([u], fragment("? < now() - interval '2 years'", field(u, ^field_name)))
    |> where([u], not u.is_admin and not u.is_delegate)
    |> where([u], not like(u.email, ^"%#{@anonymous_mail_domain}"))
  end

  def anonymize(%User{} = user) do
    %User{applications: applications} = Repo.preload(user, [applications: :resumes])
    Enum.each(applications, &anonymize(&1))

    first_name = Vae.String.random_human_readable_name()
    last_name = Vae.String.random_human_readable_name()

    User.changeset(user, %{
      email: "#{first_name}.#{last_name}#{@anonymous_mail_domain}",
      first_name: first_name,
      last_name: last_name,
      pe_id: nil,
      job_seeker_id: nil,
      identity: nil,
      password_hash: nil,
      skills: [],
      experiences: [],
      proven_experiences: [],
    })
    |> Repo.update()
  end

  def anonymize(%UserApplication{resumes: resumes} = ua) do
    Enum.each(resumes, &anonymize(&1))

    UserApplication.changeset(ua, %{
      booklet_1: nil
    })
    |> Repo.update()
  end

  def anonymize(%Resume{} = r) do
    case Resume.delete_file(r) do
      {:ok, _body} ->
        Resume.changeset(r, %{
          filename: "anonymous.pdf",
          file: nil,
          category: nil,
          url: "https://avril.pole-emploi.fr/files/anonymous.pdf"
        })
        |> Repo.update()

      error ->
        error

    end
  end

  def delete_job_seekers do
    from(j in Vae.JobSeeker)
    |> where([j], fragment("? < now() - interval '2 years'", j.updated_at))
    |> Repo.delete_all(timeout: :infinity)
    # |> Repo.aggregate(:count, :id)
  end
end