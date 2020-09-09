defmodule Vae.ExAdmin.Certification do
  use ExAdmin.Register
  alias Vae.ExAdmin.Helpers

  require Ecto.Query

  register_resource Vae.Certification do
    index do
      selectable_column()
      column(:id)
      column(:rncp_id)
      column(:acronym)
      column(:label)
      column(:level)
      column(:is_active)

      actions()
    end

    show certification do
      attributes_table()

      panel "Romes" do
        table_for certification.romes do
          column(:id)
          column(:label)
          column(:code)
        end
      end

      panel "Certifiers" do
        table_for certification.certifiers do
          column(:id)
          column(:name, &Helpers.link_to_resource/1)
        end
      end

      panel "RNCP Delegates" do
        table_for certification.rncp_delegates do
          column(:id)
          column(:name, &Helpers.link_to_resource/1)
        end
      end

      panel "Delegates" do
        table_for certification.delegates do
          column(:id)
          column(:name, &Helpers.link_to_resource/1)
        end
      end

      panel "Applications" do
        table_for certification.applications do
          column(:id)
          column(:application_user, fn a -> Helpers.link_to_resource(a.user) end)
          column(:application_delegate, fn a -> Helpers.link_to_resource(a.delegate) end)
          column(:submitted_at)
          column(:admissible_at)
          column(:inadmissible_at)
        end
      end
    end

    form certification do
      inputs do
        input(certification, :is_active)
        input(certification, :rncp_id)
        input(certification, :acronym)
        input(certification, :label)
        input(certification, :level)
        input(certification, :activity_area)
        input(certification, :activities, type: :text)
        input(certification, :abilities, type: :text)
        input(certification, :accessible_job_type, type: :text)

        # content do
        #   Helpers.form_select_tag(certification, :certifiers)
        # end

        # content do
        #   Helpers.form_select_tag(certification, :romes, fn r -> r.code end)
        # end

        # content do
        #   Helpers.form_select_tag(certification, :delegates)
        # end
      end
    end

    filter [:id, :rncp_id, :slug, :acronym, :label, :is_active, :level, :description]

    query do
      preloads = [:certifiers, :delegates, :rncp_delegates, :romes]

      %{
        index: [default_sort: [asc: :rncp_id]],
        show: [
          preload: preloads ++ [:newer_certification] ++ [
            applications: [:delegate, :user, :certification, :certifiers]
          ]
        ],
        new: [preload: preloads],
        create: [preload: preloads],
        edit: [preload: preloads],
        update: [preload: preloads],
      }
    end
  end
end
