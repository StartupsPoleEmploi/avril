require IEx;
defmodule Vae.AuthController do
  use Vae.Web, :controller

  alias Vae.Authentication
  alias Vae.Authentication.Clients
  alias Vae.User
  alias Vae.Skill
  alias Vae.Experience
  alias Vae.JobSeeker

  def save_session_and_redirect(conn, params) do
    referer = hd(get_req_header(conn, "referer"))

    client = Authentication.init_client()

    {:ok, client} = Clients.add_client(client, client.params[:state], client.params[:nonce])

    url = Authentication.get_authorize_url!(client)

    put_session(conn, :referer, referer)
    |> redirect(external: url)
  end

  def callback(conn, %{"code" => code, "state" => state} = _params) do
    client = Clients.get_client(state)
    client_with_token = Authentication.generate_access_token(client, code)

    api_calls = [
      %{
        url: "https://api.emploi-store.fr/partenaire/peconnect-individu/v1/userinfo",
        changeset: fn data -> User.userinfo_api_map(data) end
      },
      %{
        url: "https://api.emploi-store.fr/partenaire/peconnect-coordonnees/v1/coordonnees",
        changeset: fn data -> User.coordonnees_api_map(data) end
      },
      %{
        url: "https://api.emploi-store.fr/partenaire/peconnect-competences/v2/competences",
        changeset: fn data -> %{
          skills: Enum.map(data, fn skill_params -> Skill.competences_api_map(skill_params) end)
        } end
      },
      %{
        url: "https://api.emploi-store.fr/partenaire/peconnect-experiences/v1/experiences",
        changeset: fn data -> %{
          experiences: Enum.map(data, fn experience_params -> Experience.experiences_api_map(experience_params) end)
        } end
      },
    ]

    user = Enum.reduce(api_calls, nil, fn call, user ->
      IO.puts("Calling #{call.url}")
      api_result = Authentication.get(client_with_token, call.url)

      {user, extra_params} = if user == nil do
        tmp_password = "AVRIL_#{api_result.body["idIdentiteExterne"]}_TMP_PASSWORD"
        case Repo.get_by(User, pe_id: api_result.body["idIdentiteExterne"]) do
          nil  -> {%User{}, Map.merge(%{
            "email" => String.downcase(api_result.body["email"]),
            "password" => tmp_password,
            "password_confirmation" => tmp_password,
          }, get_params_from_referer(get_session(conn, :referer)))}
          user -> {user, nil} # User exists, let's use it
        end
      else
        {user, nil}
      end

      actual_changeset_params = unless is_nil(extra_params), do: Map.merge(api_result.body, extra_params), else: api_result.body

      changeset = User.changeset(user, call.changeset.(actual_changeset_params))

      case Repo.insert_or_update(changeset) do
        {:ok, user} -> user
        {:error, changeset} ->
          IO.inspect(changeset)
          nil
      end
    end)

    if user == nil do
      conn
      |> put_flash(:error, "Une erreur est survenue. Veuillez réessayer plus tard.")
      |> redirect(external: get_session(conn, :referer))

    else

      IO.inspect(user)
      IO.inspect(user_path(conn, :show, user))

      conn
      |> Coherence.Authentication.Session.create_login(user)
      |> redirect(to: user_path(conn, :show, user))
    end

  end

  defp get_params_from_referer(referer) do
    case Regex.named_captures(~r/\/diplomes\/(?<certification_id>\d+)\?certificateur=(?<delegate_id>\d+)/, referer) do
      nil -> %{}
      map -> Map.new(map, fn {k, v} -> {k, case Integer.parse(v) do
          :error -> nil
          {int, _} -> int
        end} end
      )
    end
  end

end
