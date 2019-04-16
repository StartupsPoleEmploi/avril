defmodule Vae.Statistics.StatisticsSupervisor do
  use DynamicSupervisor

  @name StatisticsSupervisor

  def start_link() do
    DynamicSupervisor.start_link(__MODULE__, :no_args, name: @name)
  end

  def start_link(_arg) do
    start_link()
  end

  def init(:no_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def add_statistic_handler() do
    DynamicSupervisor.start_child(@name, {Vae.Statistics.Handler, []})
  end

  def terminate(handler_pid) do
    DynamicSupervisor.terminate_child(@name, handler_pid)
  end
end
