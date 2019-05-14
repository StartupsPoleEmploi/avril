defmodule Vae do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      supervisor(Vae.Repo, []),
      supervisor(Vae.Endpoint, []),
      supervisor(Vae.Event.EventSupervisor, []),
      supervisor(Vae.Statistics.StatisticsSupervisor, []),
      supervisor(Vae.CRM.CrmSupervisor, []),
      worker(Vae.Scheduler, []),
      worker(Vae.Places.Cache, []),
      Vae.OAuth.Clients
    ]

    opts = [strategy: :one_for_one, name: Vae.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    Vae.Endpoint.config_change(changed, removed)
    :ok
  end
end
