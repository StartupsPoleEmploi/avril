defmodule Vae.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    repo_children = %{
      should_start: true,
      children: [
        supervisor(Vae.Repo, [])
      ]
    }

    server_children = %{
      #      should_start: Phoenix.Endpoint.server?(:vae, VaeWeb.Endpoint),
      should_start: true,
      children: [
        Pow.Store.Backend.MnesiaCache,
        supervisor(VaeWeb.Endpoint, []),
        supervisor(Vae.Event.EventSupervisor, []),
        supervisor(Vae.Statistics.StatisticsSupervisor, []),
        supervisor(Vae.Crm.CrmSupervisor, []),
        worker(Vae.Status.Server, []),
        worker(Vae.Scheduler, []),
        worker(Vae.Places.Cache, []),
        Vae.OAuth.Clients
      ]
    }

    meetings_children = %{
      should_start:
        Application.get_env(:vae, :meetings_indice) &&
          Phoenix.Endpoint.server?(:vae, VaeWeb.Endpoint),
      children: [
        worker(Vae.Meetings.StateHolder, []),
        worker(Vae.Meetings.FranceVae.Server, []),
        worker(Vae.Meetings.Afpa.Server, []),
        Vae.Meetings.FranceVae.Connection.Cache
      ]
    }

    Supervisor.start_link(
      [repo_children, server_children, meetings_children]
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
