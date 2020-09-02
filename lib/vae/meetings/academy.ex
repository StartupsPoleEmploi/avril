defmodule Vae.Meetings.Academy do
  defstruct req_id: nil,
            academy_id: nil,
            updated_at: nil,
            meetings: []

  def new(academy_id) do
    %__MODULE__{
      academy_id: academy_id
    }
  end
end
