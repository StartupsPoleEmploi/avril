defmodule Mix.Tasks.Rome.BuildWithInheritance do
  use Mix.Task

  alias Vae.{Repo, Rome}

  def run(_args) do
    {:ok, _} = Application.ensure_all_started(:vae)

    File.stream!("./priv/rome_codes.csv")
    |> CSV.decode!(headers: true, num_workers: 1)
    |> Enum.each(fn %{
        "letter" => letter,
        "category" => category,
        "subcategory" => subcategory,
        "label" => label
      } ->
        case Repo.get_by(Rome, code: "#{letter}#{category}#{subcategory}") do

          nil ->
            Repo.insert(Rome.changeset(%Rome{}, %{
              code: "#{letter}#{category}#{subcategory}",
              label: label
            }))
          _rome -> IO.write("rome exists")
        end
    end)
  end
end
