defmodule VaeWeb.Resolvers.ErrorHandler do
  def error_response(message, details) when is_binary(details),
    do: {:error, message: message, details: details}

  def error_response(message, changeset) do
    {:error, message: message, details: transform_errors(changeset)}
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
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end
end
