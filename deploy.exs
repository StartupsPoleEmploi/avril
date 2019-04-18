defmodule Vae.DeployCallbacks do
  import Gatling.Bash

  def before_mix_digest(env) do
    bash("mkdir", ~w[-p priv/static], cd: env.build_dir)
    bash("npm", ~w[install], cd: env.build_dir)
    bash("npm", ~w[run deploy], cd: env.build_dir)
  end

  def before_start_service(env) do
    bash("mix", ~w[run priv/repo/seeds.exs],
      cd: env.build_dir,
      env: [{"PORT", to_string(env.available_port)}]
    )
  end
end
