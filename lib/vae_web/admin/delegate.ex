defmodule Vae.ExAdmin.Delegate do
  use ExAdmin.Register
  alias Vae.ExAdmin.Helpers

  alias Vae.{Delegate, Process, Repo}
  require Ecto.Query

  register_resource Vae.Delegate do
    update_changeset(:changeset_update)
    create_changeset(:changeset_update)

    index do
      selectable_column()
      column(:id)
      column(:name)
      column(:is_active)
      column(:process)

      column(:certifiers, fn d ->
        Enum.map(d.certifiers, &Helpers.link_to_resource/1)
      end)
      column(:nb_applications, fn a -> length(a.applications) end)
      column(:administrative)
      column(:city)

      actions()
    end

    show delegate do
      attributes_table(
        only: [
          :id,
          :is_active,
          :slug,
          :name,
          :city,
          :administrative,
          :website,
          :address,
          :telephone,
          :email,
          :person_name,
          :secondary_email,
          :secondary_person_name,
          :process_id,
          :academy_id,
          :internal_notes
        ]
      )
      panel "Certifiers" do
        table_for delegate.certifiers do
          column(:id)
          column(:name, &Helpers.link_to_resource/1)
        end
      end

      panel "RNCP Certifications" do
        table_for delegate.rncp_certifications do
          column(:id)
          column(:name, &Helpers.link_to_resource/1)
          column(:rncp_id)
          column(:is_active)
        end
      end

      panel "Certifications" do
        table_for delegate.certifications do
          column(:id)
          column(:name, &Helpers.link_to_resource/1)
          column(:rncp_id)
          column(:is_active)
        end
      end


      # panel "Applications" do
      #   table_for delegate.applications do
      #     column(:id)
      #     column(:application_user, fn a -> Helpers.link_to_resource(a.user) end)

      #     column(:application_certification, fn a -> Helpers.link_to_resource(a.certification) end)

      #     column(:submitted_at)
      #     column(:admissible_at)
      #     column(:inadmissible_at)
      #   end
      # end

      panel "Meetings" do
        table_for delegate.meeting_places
                  |> Enum.flat_map(fn %{meetings: meetings} -> meetings end) do
          column(:meeting_id)
          # column(:name)
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
      label: "Refresh meetings"

    def refresh_meetings(conn, _infos) do
      Task.async(fn ->
        Vae.Authorities.fetch_fvae_delegate_meetings()
      end)
      conn
      |> Phoenix.Controller.put_flash(:notice, "Rafraichissement en cours")
      |> Phoenix.Controller.redirect(to: ExAdmin.Utils.admin_resource_path(Delegate))
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
        input(delegate, :address)
        input(delegate, :geo, type: :hidden)
        input(delegate, :telephone)
        input(delegate, :email)
        input(delegate, :person_name)
        input(delegate, :secondary_email)
        input(delegate, :secondary_person_name)
        input(delegate, :process, collection: Repo.all(Process))
        input(delegate, :internal_notes, type: :text)

        # content do
        #   Helpers.form_select_tag(delegate, :certifiers)
        # end

        # content do
        #   Helpers.form_select_tag(delegate, :certifications)
        # end
      end
    end

    filter([:is_active, :id, :slug, :email, :city, :administrative])

    query do
      preloads = [preload: [:process, :certifiers, :rncp_certifications, :certifications]]
      %{
        index: [preload: [:process, :certifiers, :applications], default_sort: [asc: :id]],
        show: preloads,
        new: preloads,
        create: preloads,
        edit: preloads,
        update: preloads,
      }
    end
  end
end
