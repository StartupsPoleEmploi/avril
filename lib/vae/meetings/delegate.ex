defmodule Vae.Meetings.Delegate do
  defstruct req_id: nil,
            delegate_id: nil,
            academy_id: nil,
            updated_at: nil,
            meetings: []

  def new(delegate_id, academy_id) do
    %__MODULE__{
      delegate_id: delegate_id,
      academy_id: academy_id,
      req_id: make_ref()
    }
  end
end
