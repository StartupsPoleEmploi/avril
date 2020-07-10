defmodule Vae.Booklet.Experience do
  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__
  alias Vae.Booklet.Address

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    field(:uuid, :string)
    field(:title, :string)
    field(:company_name, :string)
    field(:job_industry, :string)
    field(:employment_type, :integer)

    embeds_many :skills, Skill, primary_key: false, on_replace: :delete do
      @derive Jason.Encoder
      field(:label, :string)

      def changeset(struct, params \\ %{}) do
        struct
        |> cast(params, [:label])
      end
    end

    embeds_many :periods, Period, primary_key: false, on_replace: :delete do
      @derive Jason.Encoder
      field(:start_date, :date)
      field(:end_date, :date)
      field(:week_hours_duration, :integer)
      field(:total_hours, :integer)

      def changeset(struct, params \\ %{}) do
        struct
        |> cast(params, [:start_date, :end_date, :week_hours_duration, :total_hours])
      end
    end

    embeds_one(:full_address, Address, on_replace: :delete)
  end

  @fields ~w(
    uuid
    title
    company_name
    job_industry
    employment_type
  )a

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
    |> cast_embed(:skills)
    |> cast_embed(:periods)
    |> cast_embed(:full_address)
  end

  def job_industry_label(%Experience{job_industry: job_industry}) do
    case job_industry do
      "A" -> "Agriculture, marine, pêche"
      "B" -> "Bâtiment, travaux publics"
      "C" -> "Electricité, électronique"
      "D" -> "Mécanique, travail des métaux"
      "E" -> "Industries de process"
      "F" -> "Matériaux souples, bois, industries graphiques"
      "G" -> "Maintenance"
      "H" -> "Ingénieurs et cadres de l'industrie"
      "J" -> "Transports, logistique et tourisme"
      "K" -> "Artisanat"
      "L" -> "Gestion, administration des entreprises"
      "M" -> "Informatique et télécommunications"
      "N" -> "Études et recherche"
      "P" -> "Administration publique, professions juridiques, armée et police"
      "Q" -> "Banque et assurance"
      "R" -> "Commerce"
      "S" -> "Hôtellerie, restauration, alimentation"
      "T" -> "Services aux particuliers et aux collectivités"
      "U" -> "Communication, information, art et spectacle"
      "V" -> "Santé, action sociale, culturelle et sportive"
      "W" -> "Enseignement, formation"
      "X" -> "Politique, religion"
    end
  end

  def employment_type_label(%Experience{employment_type: employment_type}) do
    case employment_type do
      1 -> "Salarié"
      2 -> "Travailleur indépendant, artisan, profession libérale"
      3 -> "Volontaire {VIE, VIA...}"
      4 -> "Sportif de haut niveau"
      5 -> "Bénévolat"
      6 -> "Personne ayant exercé des responsabilités syndicales"
      7 -> "Mandat électoral local ou fonction élective locale"
      8 -> "En contrat d’apprentissage"
      9 -> "En contrat de professionnalisation"
      10 -> "Contrat Unique d'Insertion (CUI, CAE...)"
      11 -> "Période d'immersion (PMSMP, EMT)"
      12 -> "Préparation opérationnelle à l’emploi (POE)"
      13 -> "Période de formation en milieu professionnel (PFMP)"
      14 -> "Stage pratique dans le cadre d'une formation"
    end
  end

end
