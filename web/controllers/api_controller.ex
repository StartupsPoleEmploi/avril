defmodule Vae.ApiController do
  use Vae.Web, :controller
  require Logger

  alias Vae.{Application, Certification, User}
  alias Vae.Booklet.Cerfa

  plug Vae.Plugs.ApplicationAccess, find_with_hash: :booklet_hash

  def get_booklet(conn, %{"hash" => hash}) do
    application =
      conn.assigns[:current_application]
      |> Repo.preload([:user, :certification])

    data =
      case application.booklet_1 do
        nil ->
          with booklet <- from_application(application),
               {:ok, application} <- Application.put_booklet(application, booklet) do
            application.booklet_1
          else
            {:error, msg} ->
              Logger.error(fn -> inspect("#{msg}") end)
              %Cerfa{}
          end

        booklet ->
          booklet
      end

    json(conn, %{
      status: :ok,
      data: data
    })
  end

  def set_booklet(conn, %{"hash" => hash} = params) do
    conn.assigns[:current_application]
    |> Application.save_booklet(%{"booklet_1" => params})
    |> case do
      {:ok, _application} ->
        json(conn, %{
          status: :ok
        })

      {:error, error} ->
        json(conn, %{
          status: :error,
          error: error
        })
    end
  end

  def from_application(application) do
    user = application.user

    %Vae.Booklet.Cerfa{
      certification_name: Certification.name(application.certification),
      civility: %Vae.Booklet.Civility{
        gender: user.gender,
        birthday: user.birthday,
        birth_place: %Vae.Booklet.Address{
          city: user.birth_place
        },
        first_name: user.first_name,
        last_name: user.last_name,
        email: user.email,
        mobile_phone: user.phone_number,
        full_address: %Vae.Booklet.Address{
          city: user.city_label,
          country: user.country_label,
          postal_code: user.postal_code,
          street: User.address_street(user)
        }
      },
      experiences: user.proven_experiences |> group_experiences() |> map_experiences()
    }
  end

  def group_experiences([]), do: []

  def group_experiences(experiences) do
    Enum.group_by(experiences, fn experience ->
      [experience.company_name, experience.label, experience.contract_type]
    end)
  end

  def merge_periods_into_experience([], acc), do: acc

  def merge_periods_into_experience([h | t], acc) do
    merge_periods_into_experience(
      t,
      %Vae.Booklet.Experience{
        acc
        | title: h.label,
          company_name: h.company_name,
          full_address: nil,
          employment_type: h.contract_type,
          periods: [
            %Vae.Booklet.Experience.Period{
              start_date: h.start_date,
              end_date: h.end_date,
              week_hours_duration: 35
            }
            | acc.periods
          ]
      }
    )
  end

  def map_experiences([]), do: []

  def map_experiences(experiences) do
    Enum.map(experiences, fn {[company_name, label, contract], data} ->
      merge_periods_into_experience(data, %Vae.Booklet.Experience{})
    end)
  end
end
