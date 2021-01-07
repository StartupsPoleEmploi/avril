defmodule Vae.Repo do
  use Ecto.Repo, otp_app: :vae, adapter: Ecto.Adapters.Postgres
  use Scrivener, page_size: 20

  alias __MODULE__

  def stream_preload(stream, size, preloads) do
    stream
    |> Stream.chunk_every(size)
    |> Stream.flat_map(fn chunk ->
      Repo.preload(chunk, preloads)
    end)
  end
end
