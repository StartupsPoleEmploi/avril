defmodule Vae do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      supervisor(Vae.Repo, []),
      supervisor(Vae.Endpoint, []),
      supervisor(Vae.Event.EventSupervisor, []),
      supervisor(Vae.Statistics.StatisticsSupervisor, []),
      supervisor(Vae.Crm.CrmSupervisor, []),
      worker(Vae.Scheduler, []),
      worker(Vae.Places.Cache, []),
      Vae.OAuth.Clients,
      Vae.Delegates.Cache,
      worker(Vae.Delegates.FranceVae.Server, [:france_vae]),
      worker(Vae.Delegates.Afpa.Server, [:afpa])
    ]

    opts = [strategy: :one_for_one, name: Vae.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    Vae.Endpoint.config_change(changed, removed)
    :ok
  end
end
