defmodule Vae.Statistics.Handler do
  use GenServer

  alias Vae.{Certification, JobSeeker}

  @email_config Application.get_env(:vae, :statistics)

  def child_spec(month) do
    %{
      id: __MODULE__,
      restart: :temporary,
      start: {__MODULE__, :start_link, [[month: month]]},
      type: :worker
    }
  end

  def start_link(args) do
    month = args[:month]
    {:ok, month}
  end

  def init(args) do
    {:ok, args}
  end

  def handle_call(:execute, _from, state) do
    JobSeeker.list_from_events_month(DateTime.utc_now())
    |> build_records()
    |> build_csv()

    #    |> write()
    #    |> send_email()

    {:reply, :ok, state}
  end

  def foo() do
    JobSeeker.list_from_events_month(DateTime.utc_now())
    |> build_records()
    |> build_csv()
    |> write()
    |> send_email()
  end

  defp build_records(job_seekers) do
    job_seekers.rows
    |> Enum.map(&Vae.Repo.load(JobSeeker, {job_seekers.columns, &1}))
    |> Enum.reduce([], fn js, acc ->
      case filter_by_empty_event_payload(js.events) do
        [] ->
          acc

        events ->
          experiences = build_experiences(js)
          count = length(experiences)

          {_count, full_experiences} =
            Enum.reduce(experiences, {count, %{}}, fn experience, {count, acc} ->
              {count - 1,
               Map.merge(
                 acc,
                 %{
                   "DL_ROME_#{count}" => experience.code,
                   "DL_ROME_#{count}_LABELS" => experience.labels,
                   "DL_ROME_#{count}_DURATION" => experience.duration,
                   "education_level" => js.education_level,
                   "identifier" => js.identifier,
                   "postal_code" => js.postal_code,
                   "DL_first_name" => js.first_name,
                   "DL_last_name" => js.last_name,
                   "DL_email" => js.email,
                   "DL_postal_code" => js.postal_code
                 }
               )}
            end)

          events
          |> Enum.map(fn event ->
            {payload, _} = Code.eval_string(event.payload)

            Map.put(payload, "date", time_to_string(event.time))
            |> Map.merge(full_experiences)
          end)
          |> Kernel.++(acc)
      end
    end)
  end

  defp build_csv(records) do
    records
    |> CSV.encode(
      headers: [
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
    )
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
        #        Email: "statistiques@avril.pole-emploi.fr",
        #        Name: "Avril Statistiques"
      },
      To: [
        %{
          Email: @email_config.email_to,
          Name: @email_config.email_to_name
          #          Email: "avril@pole-emploi.fr",
          #          Name: "Avril"
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

  defp filter_by_empty_event_payload(events) do
    Enum.filter(events, fn event -> not is_nil(event.payload) end)
  end

  def build_experiences(job_seeker) do
    case job_seeker.experience do
      nil ->
        [%Vae.Statistics.Experience{}]

      map ->
        map
        |> Enum.map(fn {key, value} ->
          certifications_labels =
            Certification.from_rome(key)
            |> case do
              nil ->
                nil

              certifications ->
                certifications
                |> Enum.map(fn certification ->
                  certification.label
                end)
                |> Enum.join(", ")
            end

          %Vae.Statistics.Experience{
            labels: certifications_labels,
            code: key,
            duration: value
          }
        end)
    end
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
