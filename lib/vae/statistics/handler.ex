defmodule Vae.Statistics.Handler do
  use GenServer

  alias Vae.{Certification, JobSeeker}

  @email_config Application.get_env(:vae, :statistics)
  @csv_headers [
    "date",
    "identifier",
    "DL_first_name",
    "DL_last_name",
    "DL_email",
    "name",
    "first_name",
    "last_name",
    "email",
    "delegate_email",
    "delegate_name",
    "job",
    "DL_ROME_1",
    "DL_ROME_1_LABELS",
    "DL_ROME_1_DURATION",
    "DL_ROME_2",
    "DL_ROME_2_LABELS",
    "DL_ROME_2_DURATION",
    "education_level",
    "certification",
    "county",
    "DL_postal_code",
    "contact_delegate",
    "phone_number"
  ]

  def child_spec() do
    %{
      id: __MODULE__,
      restart: :temporary,
      start: {__MODULE__, :start_link, []},
      type: :worker
    }
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(args) do
    PersistentEts.new(:romes, "romes.tab", [:named_table])
    {:ok, args}
  end

  def handle_call(:execute, _from, state) do
    JobSeeker.list_from_events_month(DateTime.utc_now())
    |> build_records()
    |> build_csv()
    |> write()
    |> send_email()

    {:reply, :ok, state}
  end

  defp build_records(job_seekers) do
    job_seekers.rows
    |> Enum.map(&Vae.Repo.load(JobSeeker, {job_seekers.columns, &1}))
    |> Enum.reduce([], fn js, acc ->
      case filter_by_empty_event_payload(js.events) do
        [] ->
          acc

        events ->
          build(js, events)
          |> Kernel.++(acc)
      end
    end)
  end

  defp filter_by_empty_event_payload(events) do
    Enum.filter(events, fn event -> not is_nil(event.payload) end)
  end

  defp build(job_seeker, events) do
    with experiences <- build_experiences(job_seeker),
         job_seeker <- build_job_seeker(job_seeker),
         events <- build_events(events) do
      Enum.map(events, fn event ->
        event
        |> Map.merge(job_seeker)
        |> Map.merge(experiences)
      end)
    end
  end

  defp build_experiences(job_seeker) do
    case job_seeker.experience do
      nil ->
        [%Vae.Statistics.Experience{}]

      map ->
        map
        |> Enum.map(fn {key, value} ->
          %Vae.Statistics.Experience{
            labels: get_certification_labels_from_rome_code(key),
            code: key,
            duration: value
          }
        end)
    end
    |> prepare_experiences_to_export()
  end

  defp get_certification_labels_from_rome_code(key) do
    case :ets.lookup(:romes, key) do
      [] ->
        case Certification.from_rome(key) do
          nil ->
            nil

          certifications ->
            labels =
              certifications
              |> Enum.map(fn certification ->
                certification.label
              end)
              |> Enum.join(", ")

            :ets.insert(:romes, {key, labels})
        end

      [labels] ->
        labels
    end
  end

  defp prepare_experiences_to_export(experiences) do
    count = length(experiences)

    Enum.reduce(experiences, {count, %{}}, fn experience, {count, acc} ->
      {
        count - 1,
        Map.merge(
          acc,
          %{
            "DL_ROME_#{count}" => experience.code,
            "DL_ROME_#{count}_LABELS" => experience.labels,
            "DL_ROME_#{count}_DURATION" => experience.duration
          }
        )
      }
    end)
    |> Kernel.elem(1)
  end

  defp build_job_seeker(job_seeker) do
    %{
      "education_level" => job_seeker.education_level,
      "identifier" => job_seeker.identifier,
      "postal_code" => job_seeker.postal_code,
      "DL_first_name" => job_seeker.first_name,
      "DL_last_name" => job_seeker.last_name,
      "DL_email" => job_seeker.email,
      "DL_postal_code" => job_seeker.postal_code
    }
  end

  defp build_events(events) do
    events
    |> Enum.map(fn event ->
      {payload, _} = Code.eval_string(event.payload)

      Map.put(payload, "date", time_to_string(event.time))
    end)
  end

  defp build_csv(records) do
    CSV.encode(records, headers: @csv_headers)
  end

  defp write(records) do
    %Date{month: month, year: year, day: day} = Date.utc_today()
    folder_name = "#{year}#{month |> zero_pad()}"
    path = File.cwd!() <> "/tmp/" <> folder_name
    :ok = File.mkdir_p!(path)
    file_path = "#{path}/#{year}-#{month |> zero_pad()}-#{day |> zero_pad()}.csv"

    file = File.open!(file_path, [:write, :utf8])
    Enum.each(records, &IO.write(file, &1))

    file_path
  end

  defp send_email(file) do
    content = %{
      Subject: "Hello voici les Stats !",
      From: %{
        Email: @email_config.email_from,
        Name: @email_config.email_from_name
      },
      To: [
        %{
          Email: @email_config.email_to,
          Name: @email_config.email_to_name
        }
      ],
      Attachments: [
        %{
          ContentType: "text/csv",
          Filename: Path.basename(file),
          Base64Content: File.read!(file) |> Base.encode64()
        }
      ],
      TextPart:
        "Hello toi qui aimes les chiffres, voici les statistiques du mois précédent sur les mises en relation Users -> Delegataires.\r\nTu peux maintenant reprendre une activité normale.\r\nBonne journée,\r\nAvril."
    }

    Mailjex.Delivery.send(%{
      Messages: [content]
    })
  end

  defp time_to_string(%DateTime{
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
