defmodule Vae.ApplicationController do
  require Logger
  use Vae.Web, :controller
  # plug Coherence.Authentication.Session, protected: true

  alias Vae.User
  alias Vae.Application

  def show(conn, %{"id" => id} = params) do
    application = case Repo.get(Application, id) do
      nil -> nil
      application -> Repo.preload(application, [:user, :delegate, :certification])
    end

    case has_access?(conn, application, params["hash"]) do
      {:ok, application} ->
        render(conn, "show.html",
          application: application,
          delegate: application.delegate,
          certification: application.certification,
          user: application.user,
          grouped_experiences: application.user.proven_experiences
            |> Enum.group_by(fn exp -> {exp.company_name, exp.label} end)
            |> map_values(fn experiences -> Enum.sort_by(experiences, fn exp -> Date.to_erl(exp.start_date) end, &>/2) end)
            |> Map.to_list
            |> Enum.sort_by(fn {k, v} -> Date.to_erl(List.first(v).start_date) end, &>/2),
          edit_mode: Coherence.logged_in?(conn) && Coherence.current_user(conn).id == application.user.id,
          changeset: User.changeset(application.user, %{})
        )
      {:error, %{to: to, msg: msg}} ->
        conn
        |> put_flash(:error, msg)
        |> redirect(to: to)
    end
  end

  # TODO: change to submit
  def update(conn, %{"id" => id}) do
    application = case Repo.get(Application, id) do
      nil -> nil
      application -> Repo.preload(application, [:user, :delegate, :certification])
    end

    case has_access?(conn, application, nil) do
      {:ok, application} ->
        case Application.submit(application) do
          {:ok, application} ->
            conn
            |> put_flash(:success, "Dossier transmis avec succès!")
            |> redirect(to: application_path(conn, :show, application))
          {:error, msg} ->
            conn
            |> put_flash(:error, "Une erreur est survenue: \"#{msg}\". N'hésitez pas à nous contacter pour plus d'infos.")
            |> redirect(to: application_path(conn, :show, application))
        end
      {:error, %{to: to, msg: msg}} ->
        conn
        |> put_flash(:error, msg)
        |> redirect(to: to)
    end
  end

  def download(conn, %{"application_id" => id}) do
    application = case Repo.get(Application, id) do
      nil -> nil
      application -> Repo.preload(application, [:user, {:delegate, :process}, :certification])
    end

    case has_access?(conn, application, nil) do
      {:ok, application} ->
        case Vae.StepsPdf.create_pdf_file(application.delegate.process) do
          {:ok, file} ->
            conn
              |> put_resp_content_type("application/pdf", "utf-8")
              |> send_file(200, file)
          {:error, msg} ->
            conn
              |> put_flash(:error, "Une erreur est survenue: #{msg}. Merci de reéssayer plus tard.")
              |> redirect(to: application_path(conn, :show, application))
        end
      {:error, %{to: to, msg: msg}} ->
        conn
        |> put_flash(:error, msg)
        |> redirect(to: to)
    end
  end

  defp has_access?(conn, application, nil) do
    if not is_nil(application) do
      if Coherence.logged_in?(conn) && Coherence.current_user(conn).id == application.user.id do
        {:ok, application}
      else
        {:error, %{to: session_path(conn, :new, %{"mode" => "pe-connect"}), msg: "Vous devez vous connecter"}}
      end
    else
      {:error, %{to: root_path(conn, :index), msg: "Vous n'avez pas accès."}}
    end
  end

  defp has_access?(conn, application, hash) do
    if not is_nil(application)
      && application.delegate_access_hash == hash
      # && Timex.before?(Timex.today, Timex.shift(application.delegate_access_refreshed_at, days: 10))
      do
      {:ok, application}
    else
      {:error, %{to: root_path(conn, :index), msg: (if application.delegate_access_hash == hash, do: "Accès expiré", else: "Vous n'avez pas accès")} }
    end
  end

  defp map_values(map, map_func) do
    Map.new(map, fn {k, v} -> {k, map_func.(v)} end)
  end

  defp compact_experiences(experiences, equality_fun) do
    Enum.reduce(experiences, [], fn exp, result -> associate_if_match(exp, result, equality_fun) end)
      |> Enum.reverse
      |> Enum.map(fn experiences_group -> Enum.reverse(experiences_group) end)
  end

  defp associate_if_match(element, already_associated, equality_fun) do
    case already_associated do
      [] -> [[element]]
      [[latest_element | other_elements] = previous_elements | tail] ->
        if (equality_fun.(element, latest_element)) do
          [[element | previous_elements] | tail]
        else
          [[element] | [previous_elements | tail]]
        end
    end
  end
end
