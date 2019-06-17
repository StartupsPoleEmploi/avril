defmodule Vae.ExAdmin.Delegate do
  use ExAdmin.Register
  alias Vae.Repo.NewRelic, as: Repo
  alias Vae.Certifier
  alias Vae.Process

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
      column(:is_active)
      column(:administrative)
      column(:city)

      actions()
    end

    show _delegate do
      attributes_table(
        only: [
          :id,
          :is_active,
          :name,
          :website,
          :address,
          :telephone,
          :email,
          :person_name,
          :process
        ]
      )
    end

    form delegate do
      inputs do
        input(delegate, :is_active)
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

    query do
      %{
        all: [
          preload: [
            certifiers: from(c in Certifier, order_by: c.name),
            process: from(p in Process, order_by: p.name)
          ]
        ]
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
