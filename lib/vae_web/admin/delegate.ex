defmodule Vae.ExAdmin.Delegate do
  use ExAdmin.Register
  alias Vae.ExAdmin.Helpers

  alias Vae.{Process, Repo}
  require Ecto.Query

  register_resource Vae.Delegate do
    update_changeset(:changeset_update)
    create_changeset(:changeset_update)

    index do
      selectable_column()
      column(:id)
      column(:name)
      column(:process)

      column(:certifiers, fn d ->
        Enum.map(d.certifiers, &Helpers.link_to_resource/1)
      end)

      column(:administrative)
      column(:city)

      column(:is_active)
      actions()
    end

    show delegate do
      attributes_table(
        only: [
          :id,
          :is_active,
          :slug,
          :name,
          :website,
          :address,
          :telephone,
          :email,
          :person_name,
          :process_id,
          :academy_id
        ]
      )

      panel "Certifications" do
        table_for delegate.certifications do
          column(:id)
          column(:name, &Helpers.link_to_resource/1)
          column(:rncp_id)
        end
      end

      panel "Certifiers" do
        table_for delegate.certifiers do
          column(:id)
          column(:name, &Helpers.link_to_resource/1)
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
        input(delegate, :process, collection: Repo.all(Process))

        content do
          Helpers.form_select_tag(delegate, :certifiers)
        end

        content do
          Helpers.form_select_tag(delegate, :certifications)
        end
      end
    end

    filter([:id, :slug, :is_active, :email, :city, :administrative])

    query do
      preloads = [preload: [:process, :certifiers, :certifications]]
      %{
        index: [preload: [:process, :certifiers], default_sort: [asc: :id]],
        show: preloads,
        new: preloads,
        create: preloads,
        edit: preloads,
        update: preloads,
      }
    end
  end
end
