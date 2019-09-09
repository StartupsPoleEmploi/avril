defmodule Vae.Meetings.Delegate do
  defstruct name: nil, updated_at: nil, meetings: [], grouped_meetings: []

  def new(name) do
    %__MODULE__{name: name}
  end
end
