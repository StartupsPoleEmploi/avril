defmodule Vae.Repo do
  use Ecto.Repo, otp_app: :vae
  require Logger

  defmodule NewRelic do
    use NewRelixir.Plug.Repo, repo: Vae.Repo
    use Scrivener, page_size: 20

    alias Vae.Certification
    alias Vae.Delegate
    alias Vae.Repo
    alias Vae.Rome
    alias Vae.Profession

    @search_client Application.get_env(:vae, :search_client)

    # TODO: @nresni on peut pas passer en const ? genre
    # @entities [Delegate, Profession, Rome]

    defoverridable update: 2, update!: 2, insert: 2, insert!: 2, delete: 2, delete!: 2

    def insert(struct, opts) do
      case Repo.insert(struct, opts) do
        {:ok, %type{} = inserted} when type in [Certification, Delegate, Profession, Rome] ->
          save_object_index(inserted)

        t ->
          t
      end
    end

    def insert!(struct, opts) do
      case Repo.insert!(struct, opts) do
        %type{} = inserted when type in [Certification, Delegate, Profession, Rome] ->
          save_object_index!(inserted)

        t ->
          t
      end
    end

    def update(struct, opts) do
      case Repo.update(struct, opts) do
        {:ok, %type{} = updated} when type in [Certification, Delegate, Profession, Rome] ->
          save_object_index(updated)

        t ->
          t
      end
    end

    def update!(struct, opts) do
      case Repo.update!(struct, opts) do
        %type{} = updated when type in [Certification, Delegate, Profession, Rome] -> save_object_index!(updated)
        t -> t
      end
    end

    def delete(struct, opts) do
      case Repo.delete(struct, opts) do
        {:ok, %type{} = deleted} when type in [Certification, Delegate, Profession, Rome] ->
          {:ok, delete_object_index(deleted)}

        t ->
          t
      end
    end

    def delete!(struct, opts) do
      case Repo.delete!(struct, opts) do
        %type{} = deleted when type in [Certification, Delegate, Profession, Rome] ->
          delete_object_index(deleted)

        t ->
          t
      end
    end

    defp save_object_index(%type{} = struct) do
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
    end

    defp save_object_index!(struct) do
      case save_object_index(struct) do
        {:ok, value} -> value
        {:error, error} -> raise error
      end
    end

    defp delete_object_index(%type{} = struct) do
      type
      |> @search_client.get_index_name()
      |> Algolia.delete_object(struct.id)

      struct
    end
  end
end
