defmodule Vae.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    repo_children = %{
      should_start: true,
      children: [
        supervisor(Vae.Repo, []),
        Vae.Meetings.FranceVae.Connection.Cache,
        worker(Vae.Meetings.FranceVae.Server, []),
        worker(Vae.Meetings.Afpa.Server, [])
      ]
    }

    server_children = %{
      should_start: Phoenix.Endpoint.server?(:vae, VaeWeb.Endpoint),
      children: [
        supervisor(VaeWeb.Endpoint, []),
        Vae.Scheduler,
        Pow.Store.Backend.MnesiaCache,
        supervisor(Vae.Event.EventSupervisor, []),
        worker(Vae.Status.Server, []),
        Vae.PoleEmploi.OAuth.Clients,
      ]
    }

    Supervisor.start_link(
      [repo_children, server_children]
      |> Enum.filter(fn c -> c.should_start end)
      |> Enum.map(fn c -> c.children end)
      |> Enum.concat(),
      strategy: :one_for_one,
      name: Vae.Supervisor
    )
  end

  def config_change(changed, _new, removed) do
    VaeWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
