defmodule Mix.Tasks.JobSeeker.Count do
  use Mix.Task

  import Mix.Ecto

  alias Vae.Repo
  alias Vae.JobSeeker

  def run(_args) do
    ensure_started(Repo, [])
    {:ok, _started} = Application.ensure_all_started(:poison)

    from_date =
      ~N[2018-12-01 00:00:00]
      |> DateTime.from_naive!("Etc/UTC")

    end_date =
      ~N[2018-12-31 23:59:59]
      |> DateTime.from_naive!("Etc/UTC")

    file = File.open!("12_2018.csv", [:write, :utf8])

    Repo.all(JobSeeker)
    |> Enum.reduce([], fn js, acc ->
      case Enum.filter(js.events, fn event -> not is_nil(event.payload) end)
           |> Enum.filter(
             &(DateTime.compare(&1.time, from_date) in [:gt, :eq] and
                 DateTime.compare(&1.time, end_date) in [:lt, :eq])
           ) do
        [] ->
          acc

        events ->
          events
          |> Enum.map(fn e ->
            {payload, _} = Code.eval_string(e.payload)

            romes =
              case js.experience do
                nil ->
                  [%{rome: nil, exp: nil}]

                map ->
                  map
                  |> Enum.map(fn {key, value} -> %{rome: key, exp: value} end)
              end

            Map.merge(payload, %{
              "date" => time_to_string(e.time),
              "education_level" => js.education_level,
              "identifier" => js.identifier,
              "postal_code" => js.postal_code,
              "DL_first_name" => js.first_name,
              "DL_last_name" => js.last_name,
              "DL_email" => js.email,
              "DL_ROME_1" => romes |> hd() |> get_rome(),
              "DL_XP_ROME_1" => romes |> hd() |> get_exp(),
              "DL_ROME_2" => romes |> List.last() |> get_rome(),
              "DL_XP_ROME_2" => romes |> List.last() |> get_exp(),
              "DL_postal_code" => js.postal_code
            })
          end)
          |> Kernel.++(acc)
      end
    end)
    |> CSV.encode(
      headers: [
        "date",
        "identifier",
        "DL_first_name",
        "DL_last_name",
        "DL_email",
        "name",
        "email",
        "delegate_email",
        "delegate_name",
        "job",
        "DL_ROME_1",
        "DL_XP_ROME_1",
        "DL_ROME_2",
        "DL_XP_ROME_2",
        "education_level",
        "certification",
        "county",
        "DL_postal_code",
        "contact_delegate",
        "phone_number"
      ]
    )
    |> Enum.each(&IO.write(file, &1))
  end

  def time_to_string(%DateTime{
        day: day,
        month: month,
        year: year,
        hour: hour,
        minute: minute,
        second: second
      }) do
    "#{day |> zero_pad}/#{month |> zero_pad}/#{year} #{hour |> zero_pad}:#{minute |> zero_pad}:#{
      second |> zero_pad
    }"
  end

  defp zero_pad(number) do
    number
    |> Integer.to_string()
    |> String.pad_leading(2, "0")
  end

  defp get_rome(nil), do: nil
  defp get_rome(map), do: Map.get(map, :rome)

  defp get_exp(nil), do: nil
  defp get_exp(map), do: Map.get(map, :exp)
end
