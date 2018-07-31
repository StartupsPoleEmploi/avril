defmodule Vae.Mailer.Event do
  defstruct(
    event: nil,
    time: nil,
    email: nil,
    mj_campaign_id: nil,
    mj_contact_id: nil,
    customcampaign: nil,
    message_id: nil,
    custom_id: nil,
    payload: nil
  )

  def build_from_map(params) do
    for_struct = prepare_params_for_struct(params)
    struct(__MODULE__, for_struct)
  end

  def extract_custom_ids(events) do
    Enum.map(events, & &1.custom_id)
  end

  defp prepare_params_for_struct(params) do
    Enum.reduce(params, %{}, fn {k, v}, acc ->
      atomized_key = Macro.underscore(k) |> String.to_atom()
      Map.put(acc, atomized_key, v)
    end)
  end
end
