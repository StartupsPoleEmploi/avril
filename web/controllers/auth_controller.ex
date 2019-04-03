require IEx;
defmodule Vae.AuthController do
  use Vae.Web, :controller

  alias Vae.Authentication
  alias Vae.Authentication.Clients
  alias Vae.User
  alias Vae.Skill
  alias Vae.Experience
  alias Vae.ProvenExperience
  alias Vae.JobSeeker
  alias Vae.Application

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
        changeset: &User.userinfo_api_map/1
        # changeset: fn data -> User.userinfo_api_map(data) end
      },
      %{
        url: "https://api.emploi-store.fr/partenaire/peconnect-coordonnees/v1/coordonnees",
        changeset: &User.coordonnees_api_map/1
      },
      %{
        url: "https://api.emploi-store.fr/partenaire/peconnect-competences/v2/competences",
        changeset: fn data -> %{
          skills: Enum.map(data, &Skill.competences_api_map/1)
        } end
      },
      %{
        url: "https://api.emploi-store.fr/partenaire/peconnect-experiences/v1/experiences",
        changeset: fn data -> %{
          experiences: Enum.map(data, &Experience.experiences_api_map/1)
        } end
      }, %{
        # TODO: fetch longer periods
        url: "https://api.emploi-store.fr/partenaire/peconnect-experiencesprofessionellesdeclareesparlemployeur/v1/contrats?dateDebutPeriode=20170401&dateFinPeriode=20190401",
        changeset: fn data -> %{
          proven_experiences: Enum.map(data["contrats"], &ProvenExperience.experiencesprofessionellesdeclareesparlemployeur_api_map/1)
        }
        end
      }
    ]

    user = Enum.reduce(api_calls, nil, fn call, user ->
      IO.puts("Calling #{call.url}")
      api_result = Authentication.get(client_with_token, call.url)

      {user, extra_params} = if user == nil do
        tmp_password = "AVRIL_#{api_result.body["idIdentiteExterne"]}_TMP_PASSWORD"
        case Repo.get_by(User, pe_id: api_result.body["idIdentiteExterne"]) do
          nil -> {%User{}, %{
            "email" => String.downcase(api_result.body["email"]),
            "password" => tmp_password,
            "password_confirmation" => tmp_password,
          }}
          user -> { user |> Repo.preload(:job_seeker), nil } # User exists, let's use it
        end
      else
        {user, nil}
      end

      actual_changeset_params = unless is_nil(extra_params), do: Map.merge(api_result.body, extra_params), else: api_result.body

      changeset = User.changeset(user, call.changeset.(actual_changeset_params))

      user = case Repo.insert_or_update(changeset) do
        {:ok, user} ->
          application_params = Map.merge(get_certification_id_and_delegate_id_from_referer(get_session(conn, :referer)), %{
            user_id: user.id
            })
          case existing_application = Repo.get_by(Application, application_params) do
            nil ->
              changeset = Application.changeset(%Application{}, application_params)
              case Repo.insert(changeset) do
                {:ok, application} -> user
                {:error, changeset} -> nil
              end
            existing_application -> user
          end
        {:error, changeset} -> nil
      end



    end)

    if user == nil do
      conn
      |> put_flash(:error, "Une erreur est survenue. Veuillez réessayer plus tard.")
      |> redirect(external: get_session(conn, :referer))

    else
      conn
      |> Coherence.Authentication.Session.create_login(user)
      |> redirect(to: user_path(conn, :show, user))
    end

  end

  defp get_certification_id_and_delegate_id_from_referer(referer) do
    string_key_map = Regex.named_captures(~r/\/diplomes\/(?<certification_id>\d+)\?certificateur=(?<delegate_id>\d+)/, referer) || %{}
    for {key, val} <- string_key_map, into: %{}, do: {String.to_atom(key), val}
  end

end
