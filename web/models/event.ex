defmodule Vae.Event do
  use Ecto.Schema
  import Ecto.Changeset

  alias Vae.JobSeeker

  @primary_key false
  embedded_schema do
    field(:type, :string)
    field(:event, :string)
    field(:email, :string)
    field(:time, :utc_datetime)
    field(:campaign_id, :integer)
    field(:contact_id, :integer)
    field(:customcampaign, :string)
    field(:message_id, :integer)
    field(:custom_id, :string)
    field(:payload, :string)
  end

  @fields ~w(type event email campaign_id contact_id customcampaign message_id custom_id payload)a

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
    |> cast_unix_timestamp_to_datetime(params[:time])
  end

  def cast_unix_timestamp_to_datetime(changeset, timestamp) do
    datetime = DateTime.from_unix!(timestamp)
    put_change(changeset, :time, datetime)
  end

  def update_job_seeker_from_events(event_type, events) do
    events
    |> Enum.map(fn e ->
      event_type
      |> prepare_params_for_struct(e)
      |> create_or_update_job_seeker
    end)
  end

  def extract_custom_ids(events) do
    Enum.map(events, & &1.custom_id)
  end

  def create_or_update_job_seeker(event) do
    case JobSeeker.retrieve_by_email(event.email) do
      nil ->
        JobSeeker.create_from_event(event)
        |> Vae.Repo.insert!()

      job_seeker ->
        job_seeker
        |> JobSeeker.update_event_changeset(event)
        |> Vae.Repo.update!()
    end
  end

  def build_from_map(event_type, params) do
    for_struct = prepare_params_for_struct(event_type, params)
    struct(__MODULE__, for_struct)
  end

  defp prepare_params_for_struct(:email, params) do
    Enum.reduce(params, %{type: "email"}, fn {k, v}, acc ->
      atomized_key = Macro.underscore(k) |> String.to_atom() |> map_to()
      Map.put(acc, atomized_key, v)
    end)
  end

  defp map_to(:mj_campaign_id), do: :campaign_id
  defp map_to(:mj_contact_id), do: :contact_id
  defp map_to(atom), do: atom
end
