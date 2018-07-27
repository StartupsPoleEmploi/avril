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
  def init(state) do
    PersistentEts.new(:emails, "emails.tab", [:named_table])
    {:ok, state}
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
    Enum.each(emails, fn email -> :ets.insert(:emails, {email.custom_id, email}) end)
    {:noreply, emails}
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
end
