defmodule Vae.Booklet.Education do
  use Ecto.Schema
  import Ecto.Changeset

  alias Vae.Booklet.{Course, Diploma}

  embedded_schema do
    field(:grade, :string)
    field(:degree, :string)

    embeds_many :diplomas, Diploma, primary_key: false, on_replace: :delete do
      field(:label, :string)
    end

    embeds_many :courses, Course, primary_key: false, on_replace: :delete do
      field(:label, :string)
    end
  end
end
