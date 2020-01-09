defmodule Vae.Booklet do
  require Logger

  alias Vae.Booklet.WorkerSupervisor

  def new_cerfa(id) do
    case WorkerSupervisor.add_worker(id) do
      {:ok, _pid} = ok ->
        Logger.info(fn -> "Init #{id} booklet worker" end)
        ok

      {:error, msg} ->
        Logger.error(fn -> "Error while starting #{id} booklet worker: #{inspect(msg)}" end)
    end
  end

  def set({data, id}) do
    Vae.Booklet.Worker.set({data, id})
  end
end
