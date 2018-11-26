defmodule Mix.Tasks.JobSeeker.Count do
  use Mix.Task

  import Mix.Ecto
  import Ecto.Query

  alias Vae.Repo
  alias Vae.{Delegate, JobSeeker}

  def run(_args) do
    ensure_started(Repo, [])
    {:ok, _started} = Application.ensure_all_started(:poison)

    # date = ~N[2018-11-19 00:00:00]

    # delegates_email =
    #  from(d in Delegate,
    #    where: d.administrative == "Nouvelle-Aquitaine"
    #  )
    #  |> Repo.all()
    #  |> Enum.map(& &1.email)

    job_seekers = Repo.all(JobSeeker)
    #      from(js in JobSeeker,
    #        where: js.updated_at > ^date
    #      )
    #      |> Repo.all()

    # job_seekers = Repo.all(JobSeeker)

    events = Enum.flat_map(job_seekers, fn js -> js.events end)

    file = File.open!("afpa-comma-2.csv", [:write, :utf8])

    Enum.filter(events, fn event ->
      not is_nil(event.payload)
    end)
    |> Enum.map(fn e ->
      e.payload
      |> String.replace("%", "")
      |> String.replace(" =>", ":")
      |> Poison.decode!()
      |> Map.put_new(
        "date",
        time_to_string(e.time)
      )
    end)
    |> Enum.filter(fn p ->
      (p["delegate_email"] == "cecile.cramer@afpa,fr" or
         p["delegate_email"] == "pierre-louis.teneau@afpa,fr") and p["contact_delegate"] == "on"

      # p["delegate_email"] in delegates_email and p["contact_delegate"] == "on" and
      # p["contact_delegate"] == "on" and not is_nil(p["certification"]) and
      # not is_nil(p["delegate_email"])
    end)
    |> Enum.sort_by(& &1["delegate_name"])
    |> CSV.encode(
      headers: [
        "date",
        "job",
        "certification",
        "county",
        "delegate_email",
        "delegate_name",
        "email"
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
end
