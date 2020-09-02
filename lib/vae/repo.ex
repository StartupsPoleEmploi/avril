defmodule Vae.Repo do
  use Ecto.Repo, otp_app: :vae, adapter: Ecto.Adapters.Postgres
  use Scrivener, page_size: 20
  require Logger

  alias Vae.{Certification, Delegate, Profession, Rome}
  alias __MODULE__

  @search_client Application.get_env(:vae, :search_client)
  @entities [Certification, Delegate, Profession, Rome]

  defoverridable update: 2, update!: 2, insert: 2, insert!: 2, delete: 2, delete!: 2

  def insert(struct, opts) do
    case super(struct, opts) do
      {:ok, %type{} = inserted} when type in @entities ->
        save_object_index(inserted)

      t ->
        t
    end
  end

  def insert!(struct, opts) do
    case super(struct, opts) do
      %type{} = inserted when type in @entities ->
        save_object_index!(inserted)

      t ->
        t
    end
  end

  def update(struct, opts) do
    case super(struct, opts) do
      {:ok, %type{} = updated} when type in @entities ->
        save_object_index(updated)

      t ->
        t
    end
  end

  def update!(struct, opts) do
    case super(struct, opts) do
      %type{} = updated when type in @entities -> save_object_index!(updated)
      t -> t
    end
  end

  def delete(struct, opts) do
    case super(struct, opts) do
      {:ok, %type{} = deleted} when type in @entities ->
        {:ok, delete_object_index(deleted)}

      t ->
        t
    end
  end

  def delete!(struct, opts) do
    case super(struct, opts) do
      %type{} = deleted when type in @entities ->
        delete_object_index(deleted)

      t ->
        t
    end
  end

  def stream_preload(stream, size, preloads) do
    stream
    |> Stream.chunk_every(size)
    |> Stream.flat_map(fn chunk ->
      Repo.preload(chunk, preloads)
    end)
  end

  defp save_object_index(%type{} = struct) do
    if should_save_to_index?() do
      with {:format, struct_to_index} <- {:format, type.format_for_index(struct)} do
        type
        |> @search_client.get_index_name()
        |> Algolia.save_object(struct_to_index, id_attribute: :id)

        {:ok, struct}
      else
        {:format, error} ->
          Logger.warn(fn -> inspect(error) end)
          {:error, "format error"}
      end
    else
      {:ok, struct}
    end
  end

  defp save_object_index!(struct) do
    case save_object_index(struct) do
      {:ok, value} -> value
      {:error, error} -> raise error
    end
  end

  defp should_save_to_index?() do
    Mix.env() == :prod
  end

  defp delete_object_index(%type{} = struct) do
    type
    |> @search_client.get_index_name()
    |> Algolia.delete_object(struct.id)

    struct
  end
end
