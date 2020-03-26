defmodule Vae.Meetings.EctoTypeAny do
  alias Ecto.Type
  @behaviour Type

  @impl Type
  def type, do: :any

  @impl Type
  def cast(value), do: Type.cast(:any, value)

  @impl Type
  def load(value), do: Type.load(:any, value)

  @impl Type
  def dump(value), do: Type.dump(:any, value)
end
