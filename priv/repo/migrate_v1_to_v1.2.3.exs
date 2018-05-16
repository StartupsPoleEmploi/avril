alias Ecto.Query

alias Vae.Repo
alias Vae.Delegate
alias Vae.Step
alias Vae.Certifier
alias Vae.Process
alias Vae.ProcessStep

require Ecto.Query

Certifier
|> Repo.all()
|> Repo.preload([:certifications, :delegates])
|> Enum.each(fn certifier ->
  certifier.delegates
  |> Enum.each(fn delegate ->
    processes_steps = Enum.reduce(1..8, [], fn (n, acc) ->
      with step when step != nil <- Map.get(delegate, :"step_#{n}"),
           title                 <- Floki.find(step, "h3") |> Floki.text,
           content               <- Floki.filter_out(step, "h3") |> Floki.raw_html
      do
        step = case Repo.get_by(Step, content: content) do
                 nil -> Repo.insert!(%Step{ title: title, content: content },
                                     on_conflict: [set: [content: content]],
                                     conflict_target: :content)
                 step -> step
               end
        [%ProcessStep {index: n, step: step} | acc]
      else
        _ -> acc
      end
    end)

    process = Repo.insert!(%Process{name: delegate.name,
                                    processes_steps: processes_steps},
                           on_conflict: [set: [name: delegate.name]],
                           conflict_target: :name)

    certifications = certifier |> Ecto.assoc(:certifications) |> Repo.all()

    delegate
    |> Repo.preload([:process, :certifications])
    |> Delegate.add_process(process)
    |> Repo.update!
    |> Delegate.add_certifications(certifications)
    |> Repo.update!
  end)
end)




