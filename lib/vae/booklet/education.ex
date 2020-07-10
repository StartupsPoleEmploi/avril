defmodule Vae.Booklet.Education do
  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__
  alias Vae.Booklet.{Course, Diploma}

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    field(:grade, :integer)
    field(:degree, :integer)

    embeds_many :diplomas, Diploma, primary_key: false, on_replace: :delete do
      @derive Jason.Encoder
      field(:label, :string)

      def changeset(struct, params \\ %{}) do
        struct
        |> cast(params, [:label])
      end
    end

    embeds_many :courses, Course, primary_key: false, on_replace: :delete do
      @derive Jason.Encoder
      field(:label, :string)

      def changeset(struct, params \\ %{}) do
        struct
        |> cast(params, [:label])
      end
    end
  end

  @fields ~w(grade degree)a

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
    |> cast_embed(:diplomas)
    |> cast_embed(:courses)
  end

  def grade_label(%Education{grade: grade}) do
    case grade do
      1 -> "Primaire, 6ème, 5ème, 4ème, 3ème, 1ère année de CAP/BEP"
      2 -> "2nde ou 1ère générale, 2ème année de CAP/BEP"
      3 -> "Terminale"
      4 -> "1ère ou 2ème année de l'enseignement supérieur"
      5 -> "3ème année de l'enseignement supérieur"
      6 -> "4ème ou 5ème année de l'enseignement supérieur"
      7 -> "6ème année de l'enseignement supérieur"
    end
  end

  def degree_label(%Education{degree: degree}) do
    case degree do
      1 -> "Aucun diplôme"
      2 -> "Certificat d’étude primaire"
      3 -> "Brevet des collèges (BEPC, DNB), Certificat de Formation Générale (niveau V bis)"
      4 -> "CAP, BEP ou autre certification de niveau V (niveau CEC3 : 3)"
      5 -> "Baccalauréat général, technologique, professionnel, ESEU, DAEU, ou autre certification de niveau IV (niveau CEC : 4)"
      6 -> "DEUG, DUT, DEUST, BTS ou autre certification de niveau III (niveau. CEC : 5)"
      7 -> "Licence, licence professionnelle, Maîtrise ou autre certification de niveau II (niveau CEC : 6)"
      8 -> "DESS, Master, titre d’ingénieur ou autre certification de niveau I (niveau CEC : 7)"
      9 -> "Doctorat, DEA de niveau I (niveau CEC : 8)"
      10 -> "Certificat de qualification professionnelle (CQP)"
      11 -> "Certificat de qualification professionnelle inter-branches (CQPI)"
    end
  end
end
