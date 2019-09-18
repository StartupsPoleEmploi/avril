defmodule Vae.Meetings.Delegate do
  defstruct req_id: nil,
            name: nil,
            updated_at: nil,
            meetings: [],
            indexed_meetings: [],
            grouped_meetings: []

  def new(name) do
    %__MODULE__{
      name: name,
      req_id: make_ref()
    }
  end
end
