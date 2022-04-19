defmodule Vae.Rgpd.Anonymize do
  import Ecto.Query
  import Ecto.Changeset

  alias Vae.{User, UserApplication, Repo, Resume}

  @anonymous_mail_domain "@anonymous.com"

  def anonymize_all(field_name\\:updated_at) do

    Repo.transaction(fn ->
      users_query(field_name)
      |> Repo.stream()
      |> Stream.each(&anonymize(&1))
      |> Stream.run()
    end, timeout: :infinity)

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

    user
    |> cast(%{
      email: "#{first_name}.#{last_name}#{@anonymous_mail_domain}",
      name: "#{first_name} #{last_name}",
      first_name: first_name,
      last_name: last_name,
      pe_id: nil,
      password_hash: nil
      }, [:email, :name, :first_name, :last_name, :pe_id, :password_hash])
    |> put_embed(:identity, nil)
    |> put_embed(:skills, [])
    |> put_embed(:experiences, [])
    |> put_embed(:proven_experiences, [])
    |> Repo.update()
  end

  def anonymize(%UserApplication{resumes: resumes} = ua) do
    Enum.each(resumes, &anonymize(&1))

    ua
    |> change()
    |> put_embed(:booklet_1, nil)
    |> Repo.update()
  end

  def anonymize(%Resume{} = r) do
    case Resume.delete_file(r) do
      {:ok, _body} ->
        r
        |> cast(%{
          filename: "anonymous.pdf",
          file: nil,
          category: nil,
          url: "https://avril.pole-emploi.fr/files/anonymous.pdf"
        }, [:filename, :file, :category, :url])
        |> Repo.update()

      error ->
        error

    end
  end
end