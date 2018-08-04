defmodule Vae.Event.Api do
  def new_email_event() do
    {:ok, pid} = Vae.Event.EventSupervisor.add_email_handler()
    pid
  end

  def handle_email_event(handler_pid, event) do
    GenServer.call(handler_pid, {:handle_email_event, event})
  end

  def terminate(handler_pid) do
    Vae.Event.EventSupervisor.terminate(handler_pid)
  end
end
