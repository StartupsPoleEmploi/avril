defmodule Mix.Tasks.Delegate.AddPrc do
  use Mix.Task

  import Ecto.Query

  alias Vae.Repo
  alias Vae.Certification
  alias Vae.Delegate
  alias Vae.Rome

  def run(_args) do
    {:ok, _} = Application.ensure_all_started(:vae)

    prcs = Delegate
    |> preload(:certifiers)
    |> where(is_prc: true)
    |> Repo.all()

    prcs_no_delegate = Enum.filter(prcs, fn %Delegate{certifiers: certifiers} -> length(certifiers) == 0 end)

    Enum.each(prcs_no_delegate, &(Repo.delete(&1)))

    File.stream!("priv/2023-07_list_prc.keep.csv")
    |> CSV.decode!(headers: true, num_workers: 1)
    |> Enum.each(fn %{
      "Region" => region,
      "DEPARTEMENT" => department,
      "NOM" => name,
      "Mandataire" => mandataire,
      "ADRESSE" => address,
      "TELEPHONE" => phone,
      "Mail" => email
    } ->
      %Delegate{
        is_active: true,
        is_prc: true,
        name: "#{name} - #{mandataire}",
        administrative: region,
        address: address,
        telephone: phone,
        email: email
      }
      |> Repo.insert!()
    end)
  end
end
