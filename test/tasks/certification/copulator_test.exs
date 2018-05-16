defmodule Mix.Tasks.Certification.CopulatorTest do
  use ExUnit.Case

  import SweetXml
  alias Mix.Tasks.Certification.Copulator

  @no_cards """
  <FICHES/>
  """

  @card """
  <FICHES>
    <FICHE/>
  </FICHES>
  """

  @cards """
  <FICHES>
    <FICHE/>
    <FICHE/>
    <FICHE/>
  </FICHES>
  """

  test "card list" do
    assert [] == parse(@no_cards) |> Copulator.read()
    assert 1 == parse(@card) |> Copulator.read() |> Kernel.length()
    assert 3 == parse(@cards) |> Copulator.read() |> Kernel.length()
  end

  @with_one_rome """
  <FICHES>
    <FICHE>
      <CODES_ROME>
        <ROME>
          <CODE>J1501</CODE>
        </ROME>
      </CODES_ROME>
    </FICHE>
  </FICHES>
  """

  test "match card with one rome code" do
    assert parse(@with_one_rome)
           |> xpath(~x"//FICHES/FICHE"l) ==
             parse(@with_one_rome)
             |> Copulator.read()
             |> Copulator.filter_by_rome_code("J1501")
  end

  test "no match if the rome code is not found" do
    assert [] ==
             parse(@with_one_rome)
             |> Copulator.read()
             |> Copulator.filter_by_rome_code("J1502")
  end

  @with_more_one_rome """
  <FICHES>
    <FICHE>
      <CODES_ROME>
        <ROME>
          <CODE>M4403</CODE>
        </ROME>
        <ROME>
          <CODE>J1501</CODE>
        </ROME>
      </CODES_ROME>
    </FICHE>
  </FICHES>
  """

  test "match card if rome code is member of a list of rome codes" do
    assert parse(@with_more_one_rome)
           |> xpath(~x"//FICHES/FICHE"l) ==
             parse(@with_more_one_rome)
             |> Copulator.read()
             |> Copulator.filter_by_rome_code("J1501")
  end

  test "no match with two or more rome code" do
    assert [] ==
             parse(@with_more_one_rome)
             |> Copulator.read()
             |> Copulator.filter_by_rome_code("J1502")
  end

  @active """
  <FICHES>
    <FICHE>
      <ETAT_FICHE>
        <ID>1</ID>
        <INTITULE>Publiée</INTITULE>
      </ETAT_FICHE>
      <ACTIF>Oui</ACTIF>
    </FICHE>
  </FICHES>
  """

  test "match active cards" do
    assert parse(@active)
           |> xpath(~x"//FICHES/FICHE"l) ==
             parse(@active)
             |> Copulator.read()
             |> Copulator.filter_by_active()
  end

  @not_active """
  <FICHES>
    <FICHE>
      <ETAT_FICHE>
        <ID>0</ID>
        <INTITULE>???????</INTITULE>
      </ETAT_FICHE>
    </FICHE>
  </FICHES>
  """

  test "no match on no active cards" do
    assert [] ==
             parse(@not_active)
             |> Copulator.read()
             |> Copulator.filter_by_active()
  end

  @outdated """
  <FICHES>
    <FICHE>
      <NOUVELLE_CERTIFICATION>
        <ID>6744</ID>
        <IDENTIFIANT_EXTERNE>4934</IDENTIFIANT_EXTERNE>
        <INTITULE_COMPLET>BTS Commerce international à référentiel commun européen</INTITULE_COMPLET>
      </NOUVELLE_CERTIFICATION>
    </FICHE>
  </FICHES>
  """

  test "no match on outdated cards" do
    assert [] ==
             parse(@outdated)
             |> Copulator.read()
             |> Copulator.filter_by_up_to_date()
  end

  @up_to_date """
  <FICHES>
    <FICHE>
      <FLIP>
        <FLOP>YOP</FLOP>
      </FLIP>
    </FICHE>
  </FICHES>
  """

  test "match up to date cards" do
    assert parse(@up_to_date)
           |> xpath(~x"//FICHES/FICHE"l) ==
             parse(@up_to_date)
             |> Copulator.read()
             |> Copulator.filter_by_up_to_date()
  end

  @allowed_minitries """
  <FICHES>
    <FICHE>
      <AUTORITES_RESPONSABLES>
        <AUTORITE_RESPONSABLE>
          <INTITULE>Ministère chargé des sports et de la jeunesse</INTITULE>
        </AUTORITE_RESPONSABLE>
        <AUTORITE_RESPONSABLE>
          <INTITULE>MINISTERE CHARGE DES AFFAIRES SOCIALES - Direction générale de la cohésion sociale (DGCS)</INTITULE>
        </AUTORITE_RESPONSABLE>
        <AUTORITE_RESPONSABLE>
          <INTITULE>MINISTERE CHARGE DE LA JUSTICE</INTITULE>
        </AUTORITE_RESPONSABLE>
        <AUTORITE_RESPONSABLE>
          <INTITULE>MINISTERE DE L'EDUCATION NATIONALE</INTITULE>
        </AUTORITE_RESPONSABLE>
      </AUTORITES_RESPONSABLES>
    </FICHE>
  </FICHES>
  """

  test "match allowed ministries cards" do
    assert parse(@allowed_minitries)
           |> xpath(~x"//FICHES/FICHE"l) ==
             parse(@allowed_minitries)
             |> Copulator.read()
             |> Copulator.filter_by_allowed_ministries()
  end

  @not_allowed_minitries """
  <FICHES>
    <FICHE>
      <AUTORITES_RESPONSABLES>
        <AUTORITE_RESPONSABLE>
          <INTITULE>Ministère de la défense</INTITULE>
        </AUTORITE_RESPONSABLE>
        <AUTORITE_RESPONSABLE>
          <INTITULE>MINISTERE CHARGE DE LA JUSTICE</INTITULE>
        </AUTORITE_RESPONSABLE>
      </AUTORITES_RESPONSABLES>
    </FICHE>
  </FICHES>
  """
  test "no match if ministry is not member of allowed ministry list" do
    assert [] ==
             parse(@not_allowed_minitries)
             |> Copulator.read()
             |> Copulator.filter_by_allowed_ministries()
  end

  @allowed_levels """
  <FICHES>
    <FICHE>
      <NOMENCLATURE_69>
        <ID>10</ID>
        <NIVEAU>III</NIVEAU>
        <INTITULE>Personnel occupant des emplois qui exigent normalement des formations du niveau du diplôme des Instituts Universitaires de Technologie (DUT) ou du brevet de technicien supérieur (BTS) ou de fin de premier cycle de l’enseignement supérieur.</INTITULE>
      </NOMENCLATURE_69>
    </FICHE>
  </FICHES>
  """

  test "match allowed level cards" do
    assert parse(@allowed_levels)
           |> xpath(~x"//FICHES/FICHE"l) ==
             parse(@allowed_levels)
             |> Copulator.read()
             |> Copulator.filter_by_allowed_levels()
  end

  @not_allowed_levels """
  <FICHES>
    <FICHE>
      <NOMENCLATURE_69>
        <ID>12</ID>
        <NIVEAU>IV</NIVEAU>
        <INTITULE>Personnel occupant des emplois qui exigent normalement des formations du niveau du diplôme des Instituts Universitaires de Technologie (DUT) ou du brevet de technicien supérieur (BTS) ou de fin de premier cycle de l’enseignement supérieur.</INTITULE>
      </NOMENCLATURE_69>
    </FICHE>
  </FICHES>
  """

  test "no match on not allowed level cards" do
    assert [] ==
             parse(@not_allowed_levels)
             |> Copulator.read()
             |> Copulator.filter_by_allowed_levels()
  end

  @authorities [
    "Ministère chargé des sports et de la jeunesse",
    "MINISTERE CHARGE DE LA SANTE DIRECTION GENERALE DE LA SANTE (DGS)",
    "MINISTERE CHARGE DE LA JUSTICE",
    "MINISTERE DE L'EDUCATION NATIONALE"
  ]

  test "find MINISTERE DE L'EDUCATION NATIONALE" do
    assert "MINISTERE DE L'EDUCATION NATIONALE" == Copulator.map_to_certifier(@authorities)

    assert "MINISTERE CHARGE DE LA SANTE DIRECTION GENERALE DE LA SANTE (DGS)" ==
             Copulator.map_to_certifier(Enum.take(@authorities, 3))
  end
end
