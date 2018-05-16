defmodule Vae.ExAdmin.Process do
  use ExAdmin.Register

  alias Vae.Process
  alias Vae.Delegate

  alias Vae.Repo.NewRelic, as: Repo

  alias Ecto.Query
  require Ecto.Query

  def delegates() do
    Delegate |> Query.order_by(asc: :name) |> Repo.all()
  end

  register_resource Vae.Process do
    update_changeset(:changeset_update)
    create_changeset(:changeset_update)

    index do
      selectable_column()
      column(:name)
      actions()
    end

    show process do
      attributes_table()

      panel "Delegates" do
        table_for process.delegates do
          column(:id)
          column(:name)
        end
      end
    end

    form process do
      inputs do
        input(process, :name)
        input(process, :booklet_1)
        input(process, :booklet_2)

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

    query do
      %{all: [preload: [delegates: from(d in Vae.Delegate, order_by: d.name)]]}
    end
  end
end
