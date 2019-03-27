defmodule Vae.Statistics do
  def init() do
    {:ok, pid} = Vae.Statistics.StatisticsSupervisor.add_statistic_handler()
    pid
  end

  def execute(handler_pid) do
    execute(handler_pid, DateTime.utc_now())
  end

  def execute(handler_pid, datetime) do
    GenServer.call(handler_pid, {:execute, datetime}, 60_000)
  end

  def terminate(handler_pid) do
    Vae.Statistics.StatisticsSupervisor.terminate(handler_pid)
  end
end
