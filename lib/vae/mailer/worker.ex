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
    new_emails =
      emails
      |> Enum.map(fn email ->
        email
        |> Map.update(:events, [], fn state_events ->
          state_events
          |> Enum.concat(
            events |> Enum.map(&Vae.Mailer.Event.build_from_map/1)
            |> Enum.filter(fn e -> e.custom_id == email.custom_id end)
          )
        end)
      end)

    persist(new_emails)
    {:noreply, new_emails}
  end

  @impl true
  def handle_info(msg, state) do
    IO.inspect(msg)
    {:noreply, state}
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
