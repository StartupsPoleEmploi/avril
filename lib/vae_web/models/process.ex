defmodule Vae.Process do
  use VaeWeb, :model

  alias __MODULE__

  alias Vae.{Delegate, Process, ProcessStep, Repo}

  schema "processes" do
    field(:name, :string)
    field(:booklet_1, :string)
    field(:booklet_2, :string)
    field(:booklet_address, :string)

    field(:step_1, :string)
    field(:step_2, :string)
    field(:step_3, :string)
    field(:step_4, :string)
    field(:step_5, :string)
    field(:step_6, :string)
    field(:step_7, :string)
    field(:step_8, :string)

    has_many(:delegates, Delegate, on_replace: :nilify, on_delete: :nilify_all)

    has_many(:processes_steps, ProcessStep, on_delete: :delete_all)
    has_many(:steps, through: [:processes_steps, :step])
  end

  def changeset(process, params \\ %{}) do
    process
    |> cast(
      params,
      ~w(name booklet_address booklet_1 booklet_2 step_1 step_2 step_3 step_4 step_5 step_6 step_7 step_8)a
    )
    |> validate_required([:name])
    |> unique_constraint(:name)
    |> add_delegates(params)
  end

  def add_delegates(changeset, %{delegates: delegates}) do
    changeset
    |> put_assoc(
      :delegates,
      delegates
      |> ensure_not_nil
      |> transform_destroy
      |> retrieve_delegates
      |> Enum.uniq_by(& &1.id)
    )
  end

  def add_delegates(changeset, _no_delegates_param), do: changeset

  def duplicate(process) do
    duplicate =
      process
      |> Map.take([
        :name,
        :booklet_1,
        :booklet_2,
        :step_1,
        :step_2,
        :step_3,
        :step_4,
        :step_5,
        :step_6,
        :step_7,
        :step_8
      ])
      |> Map.update(:name, "", fn name -> "#{name}_copy" end)

    %Process{}
    |> changeset(duplicate)
    |> Repo.insert()
  end

  defp ensure_not_nil(delegates) do
    delegates
    |> Enum.filter(fn {_index, %{id: d_id}} -> d_id != nil end)
  end

  defp transform_destroy(collection_with_destroy) do
    collection_with_destroy
    |> Enum.reduce([], fn {_, d}, acc ->
      case d[:_destroy] do
        "0" -> [d[:id] | acc]
        _ -> acc
      end
    end)
  end

  defp retrieve_delegates(delegate_ids) do
    Delegate
    |> where([d], d.id in ^delegate_ids)
    |> Repo.all()
  end
end
