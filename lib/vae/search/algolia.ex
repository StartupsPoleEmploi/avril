defmodule Vae.Search.Algolia do
  require Logger
  alias Vae.{Certification, Delegate, Profession, Rome, Repo, Search.QueryBuilder, Search.Utils}

  @is_sync_active Application.get_env(:algolia, :is_sync_active)
  @fvae_meetings_index "fvae_meetings"
  @synced_entities [Certification, Delegate, Profession, Rome]

  ############
  # Searches #
  ############

  def get_delegates(certification, geoloc, radius, administrative) do
    query =
      QueryBuilder.init()
      |> QueryBuilder.build_active_filter()
      |> QueryBuilder.build_administrative_filter(administrative)
      |> QueryBuilder.build_certification_filter(certification)
      |> QueryBuilder.build_geoloc(geoloc, radius)
      |> QueryBuilder.build_query()

    search(Delegate, query)
  end

  def get_france_vae_meetings(academy_id, %{ "_geoloc" => %{
    "lat" => lat,
    "lng" => lng
  }}) do
    query =
      QueryBuilder.init()
      |> QueryBuilder.build_academy_filter(academy_id)
      |> QueryBuilder.build_geoloc(%{lat: lat, lng: lng})
      |> QueryBuilder.build_query()

    search(@fvae_meetings_index, query)
  end

  defp search(entity, query) do
    entity
    |> Utils.get_index_name()
    |> Algolia.search("", query)
    |> case do
      {:ok, %{"hits" => hits}} ->
        {:ok, Utils.string_keys_to_atom(hits)}

      {:error, code, msg} ->
        {:error, "#{code}: #{msg}"}

      {:error, msg} ->
        {:error, msg}
    end
  end

  #####################
  # Index collections #
  #####################

  def index(entity) when entity in @synced_entities do
    entity
    |> Repo.all()
    |> Repo.preload(entity.preload_for_index())
    |> index()
  end

  def index([%entity{} | _] = entries) do
    do_index(entity, Enum.map(entries, &entity.format_for_index(&1)), :id)
  end

  def index_meetings(objects) do
    do_index(@fvae_meetings_index, objects, :meeting_id)
  end

  defp do_index(entity, objects, id_attribute) do
    Algolia.save_objects(Utils.get_index_name(entity), objects, id_attribute: id_attribute)
  end

  def clear_index(entity) do
    entity
    |> Utils.get_index_name()
    |> Algolia.clear_index()
  end

  ###############
  # Sync models #
  ###############

  def sync_model_to_index({:ok, %entity{} = object}) when @is_sync_active and entity in @synced_entities do
    index([object])

    {:ok, object}
  end
  def sync_model_to_index(result), do: result

  def delete_model_in_index({:ok, %entity{id: id} = object}) when @is_sync_active and entity in @synced_entities do
    entity
    |> Utils.get_index_name()
    |> Algolia.delete_object(id)

    {:ok, object}
  end
  def delete_model_in_index(result), do: result

  ##################
  # Index Settings #
  ##################

  def set_settings(entity) when entity in @synced_entities do
    entity
    |> Utils.get_index_name()
    |> Algolia.set_settings(entity.settings_for_index())
  end
end
