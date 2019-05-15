defmodule Vae.Crm do
  def init() do
    {:ok, pid} = Vae.Crm.CrmSupervisor.add_email_handler(:monthly)
    pid
  end

  def execute(handler_pid, from_date) do
    GenServer.call(handler_pid, {:execute, from_date}, :infinity)
  end

  def terminate(handler_pid) do
    Vae.Crm.CrmSupervisor.terminate(handler_pid)
  end
end
