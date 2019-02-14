defmodule Vae.Statistics do
  def init() do
    {:ok, pid} = Vae.Statistics.StatisticsSupervisor.add_statistic_handler()
    pid
  end

  def execute(handler_pid) do
    GenServer.call(handler_pid, :execute, 60_000)
  end

  def terminate(handler_pid) do
    Vae.Statistics.StatisticsSupervisor.terminate(handler_pid)
  end
end
