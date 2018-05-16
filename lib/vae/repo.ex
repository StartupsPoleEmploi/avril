defmodule Vae.Repo do
  use Ecto.Repo, otp_app: :vae
  require Logger

  defmodule NewRelic do
    use NewRelixir.Plug.Repo, repo: Vae.Repo
    use Scrivener, page_size: 20

    # TODO: clean this dirty things
    defoverridable update: 2, update!: 2, insert: 2, insert!: 2, delete: 2, delete!: 2

    def insert(struct, opts) do
      with {:ok, delegate = %Vae.Delegate{}} <- Vae.Repo.insert(struct, opts),
           {:format, delegate_to_index} <- {:format, format_delegate_for_index(delegate)} do
        "delegate"
        |> Algolia.save_object(delegate_to_index, id_attribute: :id)

        {:ok, delegate}
      else
        {:format, error} -> Logger.warn fn -> inspect(error) end
        t -> t
      end
    end

    def update(struct, opts) do
      with {:ok, delegate = %Vae.Delegate{}} <- Vae.Repo.update(struct, opts),
           {:format, delegate_to_index} <- {:format, format_delegate_for_index(delegate)} do
        "delegate"
        |> Algolia.save_object(delegate_to_index, id_attribute: :id)

        {:ok, delegate}
      else
        {:format, error} -> Logger.warn fn -> inspect(error) end
        t -> t
      end
    end

    def delete(struct, opts) do
      with {:ok, delegate = %Vae.Delegate{}} <- Vae.Repo.delete(struct, opts) do
        "delegate"
        |> Algolia.delete_object(delegate.id)

        {:ok, delegate}
      end
    end

    # TODO: extract this to a index service (duplicated code from Task.Index)
    def format_delegate_for_index(delegate) do
      delegate
      |> Map.take(Vae.Delegate.__schema__(:fields))
      |> Map.put(:_geoloc, delegate.geolocation["_geoloc"])
    end
  end
end
