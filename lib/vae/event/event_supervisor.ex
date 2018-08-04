defmodule Vae.Event.EventSupervisor do
  use DynamicSupervisor

  @name EventSupervisor

  def start_link() do
    DynamicSupervisor.start_link(__MODULE__, :no_args, name: @name)
  end

  def start_link(_arg) do
    start_link()
  end

  def init(:no_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def add_email_handler() do
    add_handler(:email)
  end

  def add_handler(event_type) do
    spec = {Vae.Event.Handler, event_type: event_type}
    DynamicSupervisor.start_child(@name, spec)
  end

  def terminate(handler_pid) do
    DynamicSupervisor.terminate_child(@name, handler_pid)
  end
end
