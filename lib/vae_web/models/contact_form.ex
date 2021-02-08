defmodule Vae.ContactForm do
  use Ecto.Schema
  import Ecto.Changeset


  schema "" do
    field :email, :string, virtual: true
    field :name, :string, virtual: true
    field :object, :string, virtual: true
    field :body, :binary, virtual: true
    field :check, :binary, virtual: true
  end

  @fields ~w(
    email
    name
    object
    body
    check
  )a

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @fields)
    |> validate_required([:email, :name, :object, :body, :check])
    |> validate_human_check()
  end

  defp validate_human_check(changeset) do
    validate_change(changeset, :check, fn (current_field, value) ->
      if value |> String.downcase() |> String.trim() == french_day_of_week() do
        []
      else
        [{:check, "Mauvaise réponse ... Seriez-vous un robot ?"}]
      end
    end)
  end

  def french_day_of_week() do
    ~w(lundi mardi mercredi jeudi vendredi samedi dimanche)
    |> Enum.at((Date.utc_today() |> Date.add(-1) |> Date.day_of_week()) - 1)
  end

end