defmodule Vae.Repo.Migrations.MigrateMeetingIdFromApplications do
  use Ecto.Migration

  import Ecto.Query

  alias Vae.UserApplication
  alias Vae.Repo

  def change do
    from(
      a in UserApplication,
      where: not is_nil(a.meeting)
    )
    |> Repo.all()
    |> Enum.map(fn application ->
      meeting = application.meeting
      new_meeting = %{meeting | meeting_id2: Integer.to_string(meeting.meeting_id)}

      Ecto.Changeset.change(application)
      |> Ecto.Changeset.put_embed(:meeting, new_meeting)
      |> Repo.update!()
    end)
  end
end
