defmodule Vae.Repo do
  use Ecto.Repo, otp_app: :vae
  require Logger

  defmodule NewRelic do
    use NewRelixir.Plug.Repo, repo: Vae.Repo
    use Scrivener, page_size: 20

    alias Vae.Delegate
    alias Vae.Repo
    alias Vae.Rome

    # TODO: clean this dirty things
    defoverridable update: 2, update!: 2, insert: 2, insert!: 2, delete: 2, delete!: 2

    def insert(struct, opts) do
      case Repo.insert(struct, opts) do
        {:ok, %type{} = inserted} when type in [Delegate, Rome] -> save_object_index(inserted)
        t -> t
      end
    end

    def insert!(struct, opts) do
      case Repo.insert!(struct, opts) do
        %type{} = inserted when type in [Delegate, Rome] -> save_object_index!(inserted)
        t -> t
      end
    end

    def update(struct, opts) do
      case Repo.update(struct, opts) do
        {:ok, %type{} = updated} when type in [Delegate, Rome] -> save_object_index(updated)
        t -> t
      end
    end

    def update!(struct, opts) do
      case Repo.update!(struct, opts) do
        %type{} = updated when type in [Delegate, Rome] -> save_object_index!(updated)
        t -> t
      end
    end

    def delete(struct, opts) do
      case Repo.delete(struct, opts) do
        {:ok, %type{} = deleted} when type in [Delegate, Rome] ->
          {:ok, delete_object_index(deleted)}

        t ->
          t
      end
    end

    def delete!(struct, opts) do
      case Repo.delete!(struct, opts) do
        %type{} = deleted when type in [Delegate, Rome] -> delete_object_index(deleted)
        t -> t
      end
    end

    defp save_object_index(%type{} = struct) do
      with {:format, struct_to_index} <- {:format, type.format_for_index(struct)} do
        type
        |> index_name()
        |> Algolia.save_object(struct_to_index, id_attribute: :id)

        {:ok, struct}
      else
        {:format, error} ->
          Logger.warn(fn -> inspect(error) end)
          {:error, "format error"}
      end
    end

    defp save_object_index!(struct) do
      case save_object_index(struct) do
        {:ok, value} -> value
        {:error, error} -> raise error
      end
    end

    defp delete_object_index(%type{} = struct) do
      type
      |> index_name()
      |> Algolia.delete_object(struct.id)

      struct
    end

    defp index_name(type) do
      type
      |> to_string()
      |> String.split(".")
      |> List.last()
      |> String.downcase()
    end
  end
end
