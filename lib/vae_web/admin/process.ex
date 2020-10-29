# Deprecated : not used anymore
# TODO: remove this
defmodule Vae.ExAdmin.Process do
  use ExAdmin.Register
  alias Vae.ExAdmin.Helpers

  alias Vae.{Delegate, Process, Repo}


  alias Ecto.Query
  require Ecto.Query

  def delegates() do
    Delegate |> Query.order_by(asc: :name) |> Repo.all()
  end

  register_resource Vae.Process do
    index do
      selectable_column()
      column(:id)
      column(:name)
      column(:booklet_address)
      actions()
    end

    show process do
      attributes_table()

      panel "Delegates" do
        table_for process.delegates do
          column(:id)
          column(:name, &Helpers.link_to_resource/1)
        end
      end
    end

    member_action(:duplicate, &__MODULE__.duplicate_action/2)

    form process do
      inputs do
        input(process, :name)
        input(process, :booklet_1)
        input(process, :booklet_2)
        input(process, :booklet_address)

        input(process, :step_1, type: :text)
        input(process, :step_2, type: :text)
        input(process, :step_3, type: :text)
        input(process, :step_4, type: :text)
        input(process, :step_5, type: :text)
        input(process, :step_6, type: :text)
        input(process, :step_7, type: :text)
        input(process, :step_8, type: :text)
      end

      inputs "Delegates" do
        has_many(process, :delegates, fn d ->
          input(
            d,
            :id,
            collection:
              Delegate
              |> Query.order_by(:name)
              |> Repo.all()
              |> Enum.map(&{&1.id, &1.name})
          )
        end)
      end
    end

    def duplicate_action(conn, params) do
      Process
      |> Repo.get(params[:id])
      |> Process.duplicate()
      |> case do
        {:ok, new_process} ->
          conn
          |> Phoenix.Controller.put_flash(:notice, "Duplicated #{new_process.name}.")
          |> Phoenix.Controller.redirect(
            to: ExAdmin.Utils.admin_resource_path(new_process, :edit)
          )

        {:error, _} ->
          conn
          |> Phoenix.Controller.put_flash(:danger, "Duplication Failed.")
          |> Phoenix.Controller.redirect(to: ExAdmin.Utils.admin_resource_path(Process))
      end
    end

    query do
      %{
        all: [preload: [delegates: from(d in Vae.Delegate, order_by: d.name)]],
        index: [default_sort: [asc: :id]]
      }
    end
  end
end
