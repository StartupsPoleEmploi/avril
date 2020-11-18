defmodule Vae.Repo do
  use Ecto.Repo, otp_app: :vae, adapter: Ecto.Adapters.Postgres
  use Scrivener, page_size: 20

  alias __MODULE__
  alias Vae.Search.Algolia

  def stream_preload(stream, size, preloads) do
    stream
    |> Stream.chunk_every(size)
    |> Stream.flat_map(fn chunk ->
      Repo.preload(chunk, preloads)
    end)
  end

  defoverridable update: 2, update!: 2, insert: 2, insert!: 2, delete: 2, delete!: 2

  def insert(struct, opts) do
    super(struct, opts)
    |> Algolia.sync_model_to_index()
  end

  def insert!(struct, opts) do
    super(struct, opts)
    |> error_wrapper(&Algolia.sync_model_to_index(&1))
  end

  def update(struct, opts) do
    super(struct, opts)
    |> Algolia.sync_model_to_index()
  end

  def update!(struct, opts) do
    super(struct, opts)
    |> error_wrapper(&Algolia.sync_model_to_index(&1))
  end

  def delete(struct, opts) do
    super(struct, opts)
    |> Algolia.delete_model_in_index()
  end

  def delete!(struct, opts) do
    super(struct, opts)
    |> error_wrapper(&Algolia.delete_model_in_index(&1))
  end

  defp error_wrapper(result, func) do
    case func.(result) do
      {:ok, object} -> object
      {:error, error} -> raise error
    end
  end
end
