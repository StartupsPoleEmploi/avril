defmodule Vae.SearchDelegate do
  require Logger

  alias Vae.Delegate
  alias Vae.Repo

  @search_client Application.get_env(:vae, :search_client)

  def get_delegate(certification, geo, postcode, administrative) do
    case get_delegates(certification, geo, postcode) do
      [head | _tail = []] ->
        preload_process(head)

      delegates ->
        delegates
        |> select_near_delegate()
    end
  end

  def get_delegates(certification, geo, postcode \\ nil) do
    geo = Map.take(geo, ["lat", "lng"])

    certification
    |> Ecto.assoc(:certifiers)
    |> Repo.all()
    |> @search_client.get_delegates(geo)
    |> case do
      {:ok, delegates} ->
        administrative = Vae.Places.get_administrative_from_postal_code(postcode)

        delegates
        |> filter_delegates_from_postalcode(postcode)
        |> filter_delegates_from_administrative_if_no_postcode_found(administrative)

      {:error, msg} ->
        Logger.error("Error on searching delegates: #{msg}")
        {[], certification |> Delegate.from_certification() |> Repo.all()}
    end
    |> case do
      {[], delegates} -> delegates
      {filtered_delegates, _delegates} -> filtered_delegates
    end
  end

  defp filter_delegates_from_postalcode(delegates, search_postcode) do
    filtered_delegates =
      Enum.filter(delegates, fn delegate ->
        case delegate.geolocation["postcode"] do
          [postcode | _tail] ->
            String.slice(postcode, 0..1) ==
              String.slice(search_postcode, 0..1)

          v when v in [[], nil] ->
            false
        end
      end)

    {filtered_delegates, delegates}
  end

  defp filter_delegates_from_administrative_if_no_postcode_found(
         {[], delegates},
         administrative
       ) do
    filtered_delegates =
      Enum.filter(delegates, fn delegate ->
        get_in(delegate, [Access.key(:geolocation), "administrative"])
        |> case do
          [admin | []] ->
            admin == administrative

          _ ->
            false
        end
      end)

    {filtered_delegates, delegates}
  end

  defp filter_delegates_from_administrative_if_no_postcode_found(tuple, _administrative),
    do: tuple

  defp select_near_delegate({[], [delegate | _delegates]}), do: preload_process(delegate)
  defp select_near_delegate({[delegate | _], _delegates}), do: preload_process(delegate)
  defp select_near_delegate({[], []}), do: nil

  defp preload_process(delegate), do: Delegate |> Repo.get(delegate.id) |> Repo.preload(:process)
end
