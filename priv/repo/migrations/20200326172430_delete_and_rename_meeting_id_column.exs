defmodule Vae.Repo.Migrations.DeleteAndRenameMeetingIdColumn do
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
    |> Enum.map(fn %{meeting: %{meeting_id2: meeting_id2}} = application ->
      new_meeting =
        application.meeting
        |> Map.drop([:meeting_id, :meeting_id2])
        |> Map.put(:meeting_id, meeting_id2)

      Ecto.Changeset.change(application)
      |> Ecto.Changeset.put_embed(:meeting, new_meeting)
      |> Repo.update!()
    end)
  end
end
