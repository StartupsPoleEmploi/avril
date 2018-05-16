defmodule Mix.Tasks.Rome.Copulator do
  use Mix.Task

  import Mix.Ecto

  alias Vae.Repo
  alias Vae.Rome
  alias Vae.Profession

  def run(_args) do
    ensure_started(Vae.Repo, [])

    with true <- rome_copulator(),
         true <- profession_copulator() do
      {:ok, "Well done !"}
    end
  end

  def rome_copulator() do
    clean = fn [code, label] ->
      up_code = String.upcase(code)

      %{
        code: up_code,
        label: String.trim(label),
        url:
          "http://candidat.pole-emploi.fr/marche-du-travail/fichemetierrome?codeRome=#{up_code}"
      }
    end

    to_struct! = &struct!(Rome, &1)

    insert_rome = fn rome ->
      Rome.changeset(rome)
      |> Repo.insert(
        on_conflict: [set: [code: rome.code, label: rome.label]],
        conflict_target: :code
      )
    end

    File.stream!("priv/fixtures/csv/romes_2.csv")
    |> CSV.decode!()
    |> Enum.map(fn item ->
      item
      |> clean.()
      |> to_struct!.()
      |> insert_rome.()
    end)
    |> Enum.all?(fn {status, %Rome{}} ->
      status == :ok
    end)
  end

  def profession_copulator() do
    insert_profession = fn rome, label ->
      Repo.insert(
        %Profession{label: label, rome: rome},
        on_conflict: [set: [label: label]],
        conflict_target: :label
      )
    end

    insert = fn %{rome: rome, label: label} ->
      case Repo.get_by(Rome, code: rome) do
        rome = %Rome{} -> insert_profession.(rome, label)
        _ -> {:ok, %Profession{}}
      end
    end

    clean = fn [rome, label] ->
      %{rome: String.upcase(rome), label: String.trim(label)}
    end

    File.stream!("priv/fixtures/csv/professions.csv")
    |> CSV.decode!()
    |> Enum.map(fn item ->
      item
      |> clean.()
      |> insert.()
    end)
    |> Enum.all?(fn {status, %Profession{}} ->
      status == :ok
    end)
  end
end
