defmodule Vae.Delegates.FranceVae.Meeting do
  use Ecto.Schema
  import Ecto.Changeset

  #  %{
  #    "addresse" => "22 sentes des Dorées",
  #    "cible" => "CAP au BTS",
  #    "date" => "04/09/2019",
  #    "heure_debut" => "14:00:00",
  #    "heure_fin" => "17:00:00",
  #    "id" => 57032,
  #    "lieu" => "Lycée Polyvalent d'Alembert, PARIS",
  #    "nom" => ""
  #  }

  @primary_key false
  embedded_schema do
    field(:academy_id, :string)
    field(:meeting_id, :string)
  end

  def changeset(module, params) do
    nil
  end
end
