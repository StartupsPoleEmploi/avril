defmodule Vae.ExAdmin.Certification do
  use ExAdmin.Register
  alias Vae.ExAdmin.Helpers

  alias Vae.{Certifier, Delegate, Repo, Rome}

  require Ecto.Query

  register_resource Vae.Certification do
    index do
      selectable_column()
      column(:id)
      column(:acronym)
      column(:label)
      column(:level)
      column(:rncp_id)

      actions()
    end

    show certification do
      attributes_table()

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

      panel "Romes" do
        table_for certification.romes do
          column(:id)
          column(:label)
          column(:code)
        end
      end

      panel "Delegates" do
        table_for certification.delegates do
          column(:id)
          column(:name, &Helpers.link_to_resource/1)
        end
      end
      panel "Certifiers" do
        table_for certification.certifiers do
          column(:id)
          column(:name, &Helpers.link_to_resource/1)
        end
      end
    end

    form certification do
      inputs do
        input(certification, :label)
        input(certification, :acronym)
        input(certification, :level)
        input(certification, :rncp_id)

        certifier_option_tags =
          Certifier
          |> Repo.all()
          |> Repo.preload(:certifications)
          |> Enum.sort_by(fn certifier -> certifier.name end)
          |> Enum.map(&option_tag(&1.id, &1.name, certification.certifiers))

        rome_options_tags =
          Rome
          |> Repo.all()
          |> Repo.preload(:certifications)
          |> Enum.sort_by(fn rome -> rome.code end)
          |> Enum.map(&option_tag(&1.id, "#{&1.code} - #{&1.label}", certification.romes))

        content do
          form_select_tag("certifiers", "Certificateurs", certifier_option_tags)
        end

        content do
          form_select_tag("romes", "Romes", rome_options_tags)
        end

        javascript do
          """
          $(document).ready(function() {
            $('#certification_romes').multiSelect();
            $('#certification_certifiers').multiSelect();
          });
          """
        end
      end

      inputs "Delegates", certification.certifications_delegates do
        has_many(certification, :certifications_delegates, fn p ->
          input(
            p,
            :delegate_id,
            collection:
              Delegate
              |> order_by(:name)
              |> Repo.all()
              |> Enum.map(&{&1.id, &1.name})
          )

          input(p, :booklet_1)
          input(p, :booklet_2)
        end)
      end
    end

    filter [:id, :label, :acronym, :level, :rncp_id, :description]


    query do
      %{
        all: [preload: [:romes, :certifiers]],
        index: [default_sort: [asc: :id]],
        show: [
          preload: [
            :romes,
            :delegates,
            :certifiers,
            applications: [:delegate, :user, :certification, :certifiers]
          ]
        ]
      }
    end
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
            id: "certification_#{id}",
            name: "certification[#{id}][]",
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
