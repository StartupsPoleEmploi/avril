defmodule Vae.Event.Handler do
  use GenServer

  alias Vae.Event

  def child_spec(event_type) do
    %{
      id: __MODULE__,
      restart: :temporary,
      start: {__MODULE__, :start_link, [[event_type: event_type]]},
      type: :worker
    }
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(args) do
    event_type = args[:event_type]
    {:ok, event_type}
  end

  def handle_call({:handle_email_event, events}, _from, event_type) do
    job_seekers = Event.update_job_seeker_from_events(event_type, events)
    {:reply, job_seekers, event_type}
  end

  def handle_call({:handle_job_seeker_event, event}, _from, event) do
    nil
  end
end
