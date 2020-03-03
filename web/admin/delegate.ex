defmodule Vae.ExAdmin.Delegate do
  use ExAdmin.Register
  alias Vae.ExAdmin.Helpers

  alias Vae.{Certifier, Process, Repo}

  alias Ecto.Query
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
      column(:is_active)
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

      panel "Applications" do
        table_for delegate.applications do
          column(:id)
          column(:application_user, fn a -> Helpers.link_to_resource(a.user) end)
          column(:application_certification, fn a -> Helpers.link_to_resource(a.certification) end)
          column(:submitted_at)
          column(:admissible_at)
          column(:inadmissible_at)
        end
      end

      panel "Meetings" do
        table_for Vae.Meetings.get(delegate) |> Enum.flat_map(&(elem(&1, 1))) do
          column(:meeting_id)
          column(:meeting_id2)
          column(:name)
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

        academies_options_tags = if length(academies_options_tags) > 0, do: academies_options_tags, else: [{nil, "No academies: France VAE not connected"}]

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
        input(delegate, :process, collection: processes())

        certifiers_options_tags =
          Certifier
          |> Repo.all()
          |> Enum.sort_by(fn certifier -> certifier.name end)
          |> Enum.map(&option_tag(&1.id, "#{&1.name}", delegate.certifiers))

        content do
          form_select_tag("certifiers", "Certifiers", certifiers_options_tags)
        end

        javascript do
          """
          $(document).ready(function() {
            $('#delegate_certifiers').multiSelect();
          });
          """
        end
      end
    end

    filter [:id, :slug, :is_active, :city, :administrative]

    query do
      %{
        all: [
          preload: [
            certifiers: from(c in Certifier, order_by: c.name),
            process: from(p in Process, order_by: p.name)
          ]
        ],
        index: [default_sort: [asc: :id]],
        show: [preload: [:process, :certifiers, :certifications, applications: [ :delegate, :user, :certification, :certifiers]]]
      }
    end
  end

  defp processes() do
    Process |> Query.order_by(:name) |> Repo.all()
  end

  defp form_select_tag(id, label, options) do
    content_tag(
      :div,
      [
        content_tag(
          :label,
          label,
          class: "col-sm-2 control-label"
        ),
        content_tag(
          :div,
          content_tag(
            :select,
            options,
            id: "delegate_#{id}",
            name: "delegate[#{id}][]",
            multiple: true
          ),
          class: "col-sm-10"
        )
      ],
      class: "form-group"
    )
  end

  defp option_tag(id, label, collection) do
    content_tag(
      :option,
      label,
      value: id,
      selected: Ecto.assoc_loaded?(collection) && Enum.any?(collection, fn c -> c.id == id end)
    )
  end
end
