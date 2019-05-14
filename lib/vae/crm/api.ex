defmodule Vae.CRM.Api do
  def new_monthly_email() do
    {:ok, pid} = Vae.CRM.CrmSupervisor.add_email_handler(:monthly)
    pid
  end

  def handle_email(handler_pid, from_date) do
    GenServer.call(handler_pid, {:execute, from_date}, :infinity)
  end

  def terminate(handler_pid) do
    Vae.CRM.CrmSupervisor.terminate(handler_pid)
  end
end
