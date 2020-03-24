defmodule VaeWeb.Context do
  @behaviour Plug

  def init(opts), do: opts

  def call(conn, _) do
    context = build_context(conn)
    Absinthe.Plug.put_options(conn, context: context)
  end

  defp build_context(conn) do
    case conn.assigns[:current_user] do
      user -> %{current_user: user}
      _ -> %{}
    end
  end

  defp build_context(_), do: %{}
end
