require IEx;
defmodule Vae.AuthController do
  use Vae.Web, :controller

  alias Vae.Authentication
  alias Vae.Authentication.Clients
  alias Vae.User
  alias Vae.Skill
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
        data_map: fn data -> %{
          email: String.downcase(data["email"]),
          name: "#{String.capitalize(data["given_name"])} #{String.capitalize(data["family_name"])}",
          pe_id: data["idIdentiteExterne"]
        } end,
      },
      %{
        url: "https://api.emploi-store.fr/partenaire/peconnect-coordonnees/v1/coordonnees",
        data_map: fn data -> %{
          postal_code: data["codePostal"],
          address1: data["adresse1"],
          address2: data["adresse2"],
          address3: data["adresse3"],
          address4: data["adresse4"],
          insee_code: data["codeINSEE"],
          country_code: data["codePays"],
          city_label: data["libelleCommune"],
          country_label: data["libellePays"]
        } end,
      },
      %{
        url: "https://api.emploi-store.fr/partenaire/peconnect-competences/v2/competences",
        data_map: fn data -> %{
          skills: Enum.map(data, fn skill_params -> Skill.changeset(%Skill{}, skill_params) end)
        } end,
      },
      %{
        url: "https://api.emploi-store.fr/partenaire/peconnect-experiences/v1/experiences",
        data_map: fn data -> %{
          experiences: data
        } end,
      },
    ]

    Enum.reduce(api_calls, nil, fn call, user ->
      api_result = Authentication.get(client_with_token, call.url)
      IO.puts("Called #{call.url}")

      user = case user do
        # nil -> case Repo.get_by(User, email: String.downcase(api_result.body["email"])) do
        nil -> case Repo.get_by(User, pe_id: api_result.body["idIdentiteExterne"]) do
          nil  -> # Initialize new user
            %User{
              password: "AVRIL_#{api_result.body["idIdentiteExterne"]}_TMP_PASSWORD",
              password_confirmation: "AVRIL_#{api_result.body["idIdentiteExterne"]}_TMP_PASSWORD",
              job_seeker: Repo.get_by(JobSeeker, email: api_result.body["email"])
            }
          user -> user # User exists, let's use it
        end
        user -> user
      end

      changeset = User.changeset(user, call.data_map.(api_result.body))

      IO.inspect(changeset)

      # IEx.pry

      case Repo.insert_or_update(changeset) do
        {:ok, user} -> user
        {:error, changeset} ->
          IO.inspect(changeset)
          nil
      end
    end)

    redirect(conn, external: get_session(conn, :referer))
  end
end
