defmodule Vae.ExAdmin.Delegate do
  use ExAdmin.Register
  alias Vae.ExAdmin.Helpers

  alias Vae.Delegate
  require Ecto.Query

  @marie_cc System.get_env("MARIE_CC_ADDRESS")

  register_resource Vae.Delegate do
    index do
      selectable_column()
      column(:id)
      column(:name)
      column(:is_active)

      column(:certifiers, fn d ->
        Enum.map(d.certifiers, &Helpers.link_to_resource(&1)) |> Enum.intersperse(", ")
      end)
      column(:nb_active_certifications, fn a -> length(a.certifications) end)
      column(:nb_applications, fn a -> length(a.applications) end)
      column(:administrative)
      column(:city)

      actions()
    end

    show delegate do
      meetings = (Vae.Meeting.find_future_meetings_for_delegate(delegate) || [])
        |> Enum.map(&(&1.data))

      attributes_table() do
        row(:is_active)
        row(:slug)
        row(:name)
        row(:address_name)
        row(:address)
        row(:city)
        row(:administrative)
        row(:telephone)
        row(:website)
        row(:email)
        row(:person_name)
        row(:secondary_email)
        row(:secondary_person_name)
        row(:academy_id)
        row(:has_coords, fn d -> if not is_nil(d.geom), do: "Yes :)", else: "No :(" end)
        row(:nb_recent_applications, fn d -> length(d.recent_applications) end)
        row(:certifications, fn d -> length(d.certifications) end)
        row(:nb_meetings, fn _d -> length(meetings) end)
        row(:internal_notes)
      end

      case delegate.geom do
        nil -> nil
        %Geo.Point{coordinates: {lng, lat}, properties: %{}, srid: nil} ->
          div ".box" do
            div ".box-header.with-border" do
              h3 "Map"
            end
            div ".box-body" do
              div "#delegate_map", [{:"data-lat", lat}, {:"data-lng", lng}]
            end
          end
      end

      panel "certifiers" do
        table_for delegate.certifiers do
          column(:id)
          column(:name, &Helpers.link_to_resource/1)
        end
      end

      panel "Recent applications" do
        table_for delegate.recent_applications do
          column(:id)
          column(:application_user, fn a -> Helpers.link_to_resource(a.user, namify: &(Vae.User.fullname(&1))) end)

          column(:application_certification, fn a -> Helpers.link_to_resource(a.certification) end)

          column(:submitted_at)
          column(:admissible_at)
          column(:inadmissible_at)
        end
      end

      panel "certifications" do
        table_for delegate.certifications do
          column(:id)
          column(:rncp_id)
          column(:is_active)
          column(:origin, fn c ->
            cond do
              Enum.find(delegate.included_certifications, &(&1.id == c.id)) -> "Extra"
              # Enum.find(delegate.excluded_certifications, &(&1.id == c.id)) -> "Excluded"
              true -> "Certifier"
            end
          end)
          column(:name, &Helpers.link_to_resource/1)
        end
      end

      # panel "excluded_certifications" do
      #   table_for delegate.excluded_certifications do
      #     column(:id)
      #     column(:rncp_id)
      #     column(:is_active)
      #     column(:name, &Helpers.link_to_resource/1)
      #   end
      # end

      panel "Meetings" do
        table_for meetings do
          column(:meeting_id)
          column(:target)
          column(:place)
          column(:address)
          column(:postal_code)
          column(:city)
          column(:remaining_places)
          column(:start_date)
          column(:end_date)
        end
      end
    end

    collection_action :"refresh-meetings",
      &__MODULE__.refresh_meetings/2,
      label: "Refresh meetings",
      icon: "refresh"

    def refresh_meetings(conn, _infos) do
      Task.async(fn -> Vae.Meetings.fetch_meetings() end)

      conn
      |> Phoenix.Controller.put_flash(:notice, "Rafraichissement en cours")
      |> Phoenix.Controller.redirect(to: ExAdmin.Utils.admin_resource_path(Delegate))
    end

    member_action :"send-recap",
      &__MODULE__.send_recap/2,
      label: "Re-send recap Email",
      icon: "envelope"

    def send_recap(conn, %{id: id}) do
      delegate = Vae.Repo.get(Vae.Delegate, id) |> Vae.Repo.preload(:recent_applications)

      if length(delegate.recent_applications) > 0 do
        case VaeWeb.DelegateEmail.applications_raise(delegate, %{cc: @marie_cc})
        |> VaeWeb.Mailer.send() do
          {:ok, _pid} ->
            conn
            |> Phoenix.Controller.put_flash(:notice, "Récapitulatif envoyé")
          _ ->
            conn
            |> Phoenix.Controller.put_flash(:danger, "Le message n'a pas pu être envoyé")
        end
      else
        conn
        |> Phoenix.Controller.put_flash(:warning, "Pas de candidatures dans les 15 derniers jours")
      end
      |> Phoenix.Controller.redirect(to: ExAdmin.Utils.admin_resource_path(delegate))
    end

    form delegate do
      inputs do
        input(delegate, :is_active)

        academies_options_tags =
          Vae.Meetings.get_france_vae_academies()
          |> Enum.sort_by(& &1["nom"])
          |> Enum.map(&{"#{&1["id"]}", "#{&1["nom"]}"})

        academies_options_tags =
          if length(academies_options_tags) > 0,
            do: academies_options_tags,
            else: [{nil, "No academies: France VAE not connected"}]

        input(delegate, :academy_id,
          label: "Académies",
          collection: academies_options_tags
        )

        input(delegate, :name)
        input(delegate, :website)
        input(delegate, :address_name)
        input(delegate, :address)
        input(delegate, :telephone)
        input(delegate, :email)
        input(delegate, :person_name)
        input(delegate, :secondary_email)
        input(delegate, :secondary_person_name)
        input(delegate, :internal_notes, type: :text)

        content do
          Helpers.form_select_tag(delegate, :excluded_certifications, [options: delegate.rncp_certifications])
        end

        content do
          other_certifications = Vae.Repo.all(Ecto.Query.from(c in Vae.Certification, where: [is_active: true])) -- delegate.rncp_certifications
          Helpers.form_select_tag(delegate, :included_certifications, [options: other_certifications, label: "Extra certifications"])
        end

      end
    end

    csv do
      column(:id)
      column(:is_active)
      column(:slug)
      column(:name)
      column(:address_name)
      column(:address)
      column(:city)
      column(:administrative)
      column(:telephone)
      column(:website)
      column(:email)
      column(:person_name)
      column(:secondary_email)
      column(:secondary_person_name)
      column(:academy_id)
      column(:internal_notes)
    end

    filter([:is_active, :id, :slug, :email, :city, :administrative, :geom])
    filter(:certifiers, order_by: :name)

    query do
      %{
        all: [preload: [:rncp_certifications, :included_certifications, :excluded_certifications]],
        index: [preload: [:certifiers, :certifications, :applications], default_sort: [asc: :id]],
        show: [preload: [:certifiers, :included_certifications, :excluded_certifications, [certifications: :certifiers], [recent_applications: [:user, :certification]]]],
        edit: [preload: [:rncp_certifications, :included_certifications, :excluded_certifications]],
        update: [preload: [:rncp_certifications, :included_certifications, :excluded_certifications]],
      }
    end
  end
end
