defmodule Vae.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    repo_children = %{
      should_start: true,
      children: [
        supervisor(Vae.Repo, []),
        worker(Vae.Places.Cache, [])
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
        worker(Vae.Meetings.Server, []),
        worker(Vae.Meetings.FranceVae.Server, []),
        Vae.Meetings.FranceVae.Connection.Cache
      ]
    }

    meetings_children = %{
      should_start:
        Application.get_env(:vae, :meetings_indice) &&
          Phoenix.Endpoint.server?(:vae, VaeWeb.Endpoint),
      children: [
        #        worker(Vae.Meetings.StateHolder, []),
        # worker(Vae.Meetings.FranceVae.Server, []),
        #        worker(Vae.Meetings.Afpa.Server, []),
        # Vae.Meetings.FranceVae.Connection.Cache
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
