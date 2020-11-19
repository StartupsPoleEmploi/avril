defmodule VaeWeb.Resolvers.Authorities do
  alias Vae.{Certification, Delegate, Repo, UserApplication}

  def certifier_item(%UserApplication{} = ua, _args, _) do
    {:ok, UserApplication.certifier(ua)}
  end

  def certifier_item(_, _args, _), do: {:ok, nil}

  def certifiers_list(%Certification{certifiers: %Ecto.Association.NotLoaded{}} = certification, args, other) do
    certification
    |> Repo.preload(:certifiers)
    |> certifiers_list(args, other)
  end

  def certifiers_list(%Certification{certifiers: certifiers}, _args, _), do: {:ok, certifiers}
  def certifiers_list(_, _args, _), do: {:ok, nil}

end
