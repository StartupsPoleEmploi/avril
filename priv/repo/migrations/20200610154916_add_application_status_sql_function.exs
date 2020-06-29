defmodule Vae.Repo.Migrations.AddApplicationStatusSQLFunction do
  use Ecto.Migration

  def change do

    Ecto.Adapters.SQL.query!(
      Vae.Repo, """

CREATE OR REPLACE FUNCTION status(a applications) RETURNS TEXT AS $$
BEGIN
  CASE
  WHEN a.admissible_at IS NOT NULL THEN
    RETURN '7-admissible';
  WHEN a.inadmissible_at IS NOT NULL THEN
    RETURN '6-inadmissible';
  WHEN a.submitted_at IS NOT NULL THEN
    RETURN '5-submitted';
  WHEN EXISTS (select 1 from resumes where resumes.application_id = a.id) THEN
    RETURN '4-resumed';
  WHEN a.booklet_1 ->> 'completed_at' IS NOT NULL THEN
    RETURN '3-booklet_finished';
  WHEN a.booklet_1 IS NOT NULL THEN
    RETURN '2-booklet_started';
  WHEN a.delegate_id IS NOT NULL THEN
    RETURN '1-delegated';
  ELSE
    RETURN '0-created';
  END CASE;
END; $$
LANGUAGE PLPGSQL;
    """ )
  end
end
