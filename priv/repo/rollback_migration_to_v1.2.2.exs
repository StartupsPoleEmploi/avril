import Ecto.Query

alias Vae.Repo
alias Vae.Process
alias Vae.ProcessStep
alias Vae.Step

Process
|> Repo.all
|> Repo.preload([processes_steps: (from ps in ProcessStep, order_by: ps.index)])
|> Enum.map(fn process ->
  Enum.reduce(process.processes_steps, process, fn process_step, process ->
    process_step = process_step
                   |> Repo.preload(:step)
    Ecto.Changeset.change process, "step_#{process_step.index}": "<h3>#{process_step.step.title}</h3>#{process_step.step.content}"
  end)
end)
|> Enum.each(&Repo.update!/1)
