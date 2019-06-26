defmodule Vae.ExAdmin.Certification do
  use ExAdmin.Register
  alias Vae.{Certifier, Delegate, Repo, Rome}

  alias Ecto.Query
  require Ecto.Query

  register_resource Vae.Certification do
    show certification do
      attributes_table()

      panel "Romes" do
        table_for certification.romes do
          column(:label)
          column(:code)
        end
      end

      panel "Delegates" do
        table_for certification.certifications_delegates do
          column("Name", & &1.delegate.name)
          column(:booklet_1)
          column(:booklet_2)
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
          |> Enum.sort_by(fn certifier -> certifier.name end)
          |> Enum.map(&option_tag(&1.id, &1.name, certification.certifiers))

        rome_options_tags =
          Rome
          |> Repo.all()
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
              |> Query.order_by(:name)
              |> Repo.all()
              |> Enum.map(&{&1.id, &1.name})
          )

          input(p, :booklet_1)
          input(p, :booklet_2)
        end)
      end
    end

    query do
      %{
        all: [
          preload: [
            romes: from(r in Rome, order_by: r.code),
            delegates: from(d in Delegate, order_by: d.name),
            certifiers: from(c in Certifier, order_by: c.name)
          ]
        ]
      }
    end
  end

  defp form_select_tag(id, label, options) do
    Phoenix.HTML.safe_to_string(content_tag(
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
    ))
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
