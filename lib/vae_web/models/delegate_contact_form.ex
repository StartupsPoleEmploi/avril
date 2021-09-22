defmodule Vae.DelegateContactForm do
  use Ecto.Schema
  import Ecto.Changeset


  schema "" do
    field :name, :string, virtual: true
    field :address, :string, virtual: true
    field :email, :string, virtual: true
    field :tel, :string, virtual: true
    field :website, :string, virtual: true
    field :person_name, :string, virtual: true
    field :comment, :string, virtual: true
    field :check, :binary, virtual: true
  end

  @fields ~w(
    name
    address
    email
    tel
    website
    person_name
    comment
    check
  )a

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @fields)
    |> validate_required([:name, :address, :email, :tel, :check])
    |> validate_human_check()
  end

  defp validate_human_check(changeset) do
    validate_change(changeset, :check, fn (_current_field, value) ->
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