defmodule VaeWeb.Resolvers.ErrorHandler do
  require Logger

  @global_error "Une erreur est survenue"

  def error_response(message, details) when is_binary(details),
    do: {:error, message: message, details: details}

  def error_response(message, %Ecto.Changeset{} = changeset) do
    log_error(changeset)
    {:error, message: message, details: transform_errors(changeset)}
  end

  def error_response(_message, error) do
    log_error(error)
    {:error, message: @global_error, details: ""}
  end

  defp transform_errors(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(&format_error/1)
    |> Enum.map(fn {key, value} ->
      %{key: key, message: value}
    end)
  end

  defp format_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", inspect(value))
    end)
  end

  defp log_error(error) do
    Logger.error(fn -> inspect(error, limit: :infinity) end)
  end
end
