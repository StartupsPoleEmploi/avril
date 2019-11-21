defmodule Vae.Booklet.WorkerSupervisor do
  use DynamicSupervisor

  @name BookletWorkerSupervisor

  def start_link() do
    DynamicSupervisor.start_link(__MODULE__, :no_args, name: @name)
  end

  def init(:no_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def add_worker(server_id) do
    DynamicSupervisor.start_child(
      @name,
      %{
        id: BookletServer,
        start: {Vae.Booklet.Worker, :start_link, [server_id]},
        restart: :transient
      }
    )
  end
end
