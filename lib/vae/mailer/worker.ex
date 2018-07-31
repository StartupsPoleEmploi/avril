defmodule Vae.Mailer.Worker do
  use GenServer

  alias Vae.Mailer.{Email, Sender}
  alias Vae.Places

  @extractor Application.get_env(:vae, :extractor)

  @name MailerWorker
  @allowed_administratives [
    "Bretagne",
    "Île-de-France",
    "Centre-Val de Loire",
    "Occitanie",
    "Bourgogne-Franche-Comté",
    "Provence-Alpes-Côte d'Azur",
    "Corse",
    "Hauts-de-France"
  ]

  @doc false
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: @name)
  end

  @impl true
  def init(_state) do
    PersistentEts.new(:emails, "emails.tab", [:named_table])
    new_state = :ets.tab2list(:emails) |> Enum.map(fn {_custom_id, email} -> email end)
    {:ok, new_state}
  end

  @impl true
  def handle_call({:extract, path}, _from, state) do
    custom_ids = Email.extract_custom_ids(state)

    emails =
      @extractor.extract(path, custom_ids)
      |> Enum.filter(&is_allowed_administrative?/1)

    new_state = emails ++ state

    {:reply, emails, new_state}
  end

  @impl true
  def handle_call(:send, _from, emails) do
    new_emails = Enum.flat_map(emails, &Sender.send/1)
    {:reply, nil, new_emails}
  end

  @impl true
  def handle_cast(:persist, emails) do
    persist(emails)
    {:noreply, emails}
  end

  @impl true
  def handle_cast({:handle_events, events}, emails) do
    new_emails = update_emails_from_events(emails, events)
    persist(new_emails)
    {:noreply, new_emails}
  end

  @impl true
  def handle_info(msg, state) do
    IO.inspect(msg)
    {:noreply, state}
  end

  @doc """
  Visible for testing
  """
  def update_emails_from_events(emails, events) do
    built_events = Enum.map(events, &Vae.Event.build_from_map/1)

    emails
    |> Enum.map(fn email ->
      filtered_events = filter_events_by_custom_id(built_events, email.custom_id)
      Map.put(email, :events, filtered_events ++ email.events)
    end)
  end

  defp filter_events_by_custom_id(events, custom_id) do
    events
    |> Enum.filter(&(&1.custom_id == custom_id))
  end

  defp is_allowed_administrative?(email) do
    administrative =
      email
      |> get_in([Access.key(:job_seeker), Access.key(:geolocation)])
      |> Places.get_administrative()

    Enum.member?(@allowed_administratives, administrative)
  end

  defp persist(emails) do
    Enum.each(emails, fn email -> :ets.insert(:emails, {email.custom_id, email}) end)
  end
end
