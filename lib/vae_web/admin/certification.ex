defmodule Vae.ExAdmin.Certification do
  use ExAdmin.Register
  alias Vae.ExAdmin.Helpers

  require Ecto.Query

  register_resource Vae.Certification do
    action_items [except: [:new, :delete]]


    index do
      selectable_column()
      column(:id)
      column(:rncp_id)
      column(:is_active)
      column(:acronym)
      column(:label)
      column(:certifiers, fn d ->
        Enum.map(d.certifiers, &Helpers.link_to_resource/1) |> Enum.intersperse(", ")
      end)
      column(:nb_active_delegates, fn a -> length(a.delegates) end)
      column(:nb_recent_applications, fn a -> length(a.recent_applications) end)

      actions()
    end

    show certification do
      attributes_table() do
        row(:rncp_id, fn c -> Phoenix.HTML.Link.link(c.rncp_id, to: "https://www.francecompetences.fr/recherche/rncp/#{c.rncp_id}/", target: "_blank") end)
        row(:last_rncp_import_date)
        row(:rncp_update, fn c ->
          if conn.params["check"] == "rncp" do
            c
            |> Vae.Certification.rncp_changeset()
            |> Map.get(:changes)
            |> IO.inspect()
            |> case do
              changes when changes == %{} -> "No changes from RNCP"
              changes -> Helpers.print_in_json(changes)
            end
          else
            Phoenix.HTML.Link.link("Check RNCP changes", to: "?check=rncp")
          end
        end)
        row(:end_of_rncp_validity)
        row(:is_rncp_active)
        row(:is_active)
        row(:newer_certification)
        row(:older_certification)
        row(:slug)
        row(:acronym)
        row(:label)
        row(:level)
        row(:nb_applications, &Helpers.count_and_link_to_all(&1, :applications))
        row(:activities)
        row(:abilities)
        row(:activity_area)
        row(:accessible_job_type)
      end

      panel "ROME" do
        table_for certification.romes do
          column(:id)
          column(:label, &Helpers.link_to_resource(&1, namify: fn r -> r.label end))
          column(:code)
        end
      end

      panel "certifiers" do
        table_for certification.certifiers do
          column(:id)
          column(:name, &Helpers.link_to_resource/1)
        end
      end

      panel "delegates" do
        table_for certification.delegates do
          column(:id)
          column(:is_active)
          column(:origin, fn d ->
            cond do
              Enum.find(certification.included_delegates, &(&1.id == d.id)) -> "Extra"
              # Enum.find(delegate.excluded_delegates, &(&1.id == d.id)) -> "Excluded"
              true -> "Certifier"
            end
          end)
          column(:name, &Helpers.link_to_resource/1)
        end
      end

      # panel "user applications" do
      #   table_for certification.applications do
      #     column(:id, &Helpers.link_to_resource(&1))
      #     column(:application_user, fn a -> Helpers.link_to_resource(a.user, namify: &(Vae.User.fullname(&1))) end)
      #     column(:application_delegate, &Helpers.link_to_resource(&1.delegate))
      #     column(:submitted_at)
      #     column(:admissible_at)
      #     column(:inadmissible_at)
      #   end
      # end
    end

    form certification do
      inputs do
        input(certification, :is_active)
        input(certification, :rncp_id, readonly: true)
        input(certification, :acronym, readonly: true)
        input(certification, :label, readonly: true)
        input(certification, :level, readonly: true)

        content do
          Helpers.form_select_tag(certification, :excluded_delegates, [
            options: certification.rncp_delegates,
            label: "Excluded delegates",
            selectable_label: "All delegates from RNCP",
            selection_label: "Excluded delegates",
          ])
        end

        content do
          other_delegates = Vae.Repo.all(Ecto.Query.from(d in Vae.Delegate, where: [is_active: true])) -- certification.rncp_delegates
          Helpers.form_select_tag(certification, :included_delegates, [
            options: other_delegates,
            label: "Extra delegates",
            selectable_label: "All delegates in Avril",
            selection_label: "Extra delegates",
          ])
        end
      end
    end

    member_action :rncp_update,
      &__MODULE__.update_rncp/2,
      label: "Refresh from RNCP",
      icon: "refresh",
      class: "rncp_forcable"

    def update_rncp(conn, %{id: id}) do
      c = Vae.Repo.get(Vae.Certification, id)

      c
      |> IO.inspect()
      |> Certification.rncp_changeset()
      |> IO.inspect()
      |> Vae.Maybe.if(conn.params["force"] == "rncp", &Certification.rncp_update!(&1), &Certification.rncp_update(&1))
      |> case do
        {:ok, %Certification{}} ->
          conn
          |> Phoenix.Controller.put_flash(:notice, "Certification mise à jour")
          |> Phoenix.Controller.redirect(to: ExAdmin.Utils.admin_resource_path(c))
        {:ok, certifiers} when is_list(certifiers) ->
          certifiers_name = Enum.map(certifiers, &(&1.name)) |> Enum.join(", ")
          conn
          |> Phoenix.Controller.put_flash(:error, "La certification n'a pas été mise à jour car les certifiers vont changer. Voici la nouvelle liste: #{certifiers_name}")
          |> Phoenix.Controller.redirect(to: "#{ExAdmin.Utils.admin_resource_path(c)}?to_force=rncp")
        _ ->
          conn
          |> Phoenix.Controller.put_flash(:error, "La certification n'a pas été mise à jour: une erreur est survenue")
          |> Phoenix.Controller.redirect(to: ExAdmin.Utils.admin_resource_path(c))
      end
    end


    filter(:newer_certification, type: :present_only)
    filter(:applications, scope: :recent)
    # filter(:delegates, scope: :active)
    filter [:is_active, :is_rncp_active, :id, :rncp_id, :slug, :acronym, :label, :level, :last_rncp_import_date, :end_of_rncp_validity, :activities]

    query do
      preloads = [:certifiers, :rncp_delegates, :included_delegates, :excluded_delegates]

      %{
        index: [default_sort: [asc: :id], preload: [:certifiers, :delegates, :recent_applications]],
        show: [
          preload: [:certifiers, :included_delegates, :excluded_delegates, [delegates: :certifiers], :romes, :newer_certification, :older_certification] ++ [
            applications: [:delegate, :user, :certification, :certifiers]
          ]
        ],
        edit: [preload: preloads],
        update: [preload: preloads],
      }
    end
  end
end
