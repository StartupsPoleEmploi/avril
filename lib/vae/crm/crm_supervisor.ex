defmodule Vae.CRM.CrmSupervisor do
  use DynamicSupervisor

  @name CrmSupervisor

  def start_link() do
    DynamicSupervisor.start_link(__MODULE__, :no_args, name: @name)
  end

  def init(:no_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def add_email_handler(type) do
    DynamicSupervisor.start_child(@name, {Vae.CRM.Handler, type})
  end

  def terminate(handler_pid) do
    DynamicSupervisor.terminate_child(@name, handler_pid)
  end
end
