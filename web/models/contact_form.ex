defmodule Vae.ContactForm do
  use Ecto.Schema
  import Ecto.Changeset


  schema "" do
    field :email, :string, virtual: true
    field :name, :string, virtual: true
    field :object, :string, virtual: true
    field :body, :binary, virtual: true
  end

  @fields ~w(
    email
    name
    object
    body
  )a

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @fields)
    #|> validate_length(:body, min: 5) - any validations, etc.
  end
end