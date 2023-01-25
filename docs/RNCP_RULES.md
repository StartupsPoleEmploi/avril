# Règles d'import RNCP

Le RNCP est le référentiel des diplômes disponibles. Nous alimentons la base d'Avril avec les
données qu'ils nous fournissent, sur la base d'un import régulier.

Toutefois, certaines données sont imprécises ou inexactes pour notre utilisation, aussi Avril
ajoute un ensemble de règles de gestion lors de l'import qui sont documentées ici-même.

## Note préalable

Ces règles d'import sont soumises à modifications relativement fréquente, aussi il est possible que
la présente documentation ne soit pas systématiquement à jour. Aussi, il peut être utile de se 
référer au code source pour connaître les dernières règles en vigueur, particulièrement en ce qui concerne
des listes de données brutes (ex: RNCP_IDs).

Le code source de ces règles est implémenté essentiellement dans deux fichiers :
- [authority_matcher.ex](https://github.com/StartupsPoleEmploi/avril/blob/master/lib/vae/authorities/rncp/authority_matcher.ex) : règles de rapprochement des certifiers
- [custom_rules.ex](https://github.com/StartupsPoleEmploi/avril/blob/master/lib/vae/authorities/rncp/custom_rules.ex) : règles de la surcouche Avril d'import des certifications

## Le rapprochement des certifiers

Du fait qu'il n'existe pas de référentiel pour les institutions fournissant des diplômes, leurs noms
ne sont pas normalisés. Aussi il est nécessaire d'effectuer un rapprochement sur les noms avec notamment
pour règles :

- transformer les chiffres romains en chiffres arabes (`paris-vii == paris-7`)
- ignorer l'ordre des mots et certains mots de liaison (`université de Paris == Paris université`)
- permettre des imprécisions d'orthographe sauf pour les noms propres (`Vincennes != Vincenne`). La liste des noms propres est disponible [ici](https://github.com/StartupsPoleEmploi/avril/blob/master/lib/vae/authorities/rncp/authority_matcher.ex#L24)

Comme cela ne suffit pas, il a fallu ajouter des aliases pour le nom de certains certifiers. Le rapprochement
s'effectue sur le slug des noms, et la liste des aliases est disponible 
[ici](https://github.com/StartupsPoleEmploi/avril/blob/master/lib/vae/authorities/rncp/authority_matcher.ex#L176)

Enfin, nous avons pris le parti de ne pas inclure la liste des certifiers disponible 
[là](https://github.com/StartupsPoleEmploi/avril/blob/master/lib/vae/authorities/rncp/authority_matcher.ex#L10)

## Certifications ignorées (non importées dans Avril) :

- les fiches qui ne sont pas accessibles en VAE (`SI_JURY_VAE != "Oui"`)
- les fiches dont l'intitulé démarre par :
  + Un des meilleurs ouvriers de France
  + Ecole polytechnique
- les fiches dont l'acronyme est :
  + BEPA

## Certifications associées à l'éducation nationale alors qu'elles ne le sont pas dans le RNCP :

- les fiches actives au RNCP associées au ministère de la solidarité
- les BTS au RNCP associées au ministère de l'enseignement suppérieur
- les ID RNCP suivants ([source](https://github.com/StartupsPoleEmploi/avril/blob/master/lib/vae/authorities/rncp/custom_rules.ex#L38)) :
  + 4875
  + 34825
  + 34826
  + 34828
  + 35044

## Certifications dissociées de l'éducation nationale alors qu'elles le sont dans le RNCP :

- les fiches avec l'un des acronymes suivants ([source](https://github.com/StartupsPoleEmploi/avril/blob/master/lib/vae/authorities/rncp/custom_rules.ex#L17)) :
  + CQP
  + DEUST
  + BUT
  + MASTER
  + Licence Professionnelle
  + Titre ingénieur
- les fiches déjà associées au ministère de la jeunesse, des sports et de la cohésion sociale
- les ID RNCP suivants ([source](https://github.com/StartupsPoleEmploi/avril/blob/master/lib/vae/authorities/rncp/custom_rules.ex#L34)) :
    + 230
    + 367
    + 2028
    + 2514
    + 2829
    + 4495
    + 4496
    + 4500
    + 4503
    + 4505
    + 18363
    + 25467
    + 28557
    + 34824
    + 34827
    + 34829
    + 34862
    + 36004

## Certification dissociée du ministère de la jeunesse, des sports et de la cohésion sociale alors qu'elle l'est dans le RNCP

- La fiche au RNCP ID 492 ([source](https://github.com/StartupsPoleEmploi/avril/blob/master/lib/vae/authorities/rncp/custom_rules.ex#L166))

## Certifications dissociées du ministère de l'agriculture alors qu'elles le sont dans le RNCP

- Les fiches dont le niveau est > 5

## Certifications rendues actives alors qu'elles sont inactives au RNCP :
- les ID RNCP suivants ([source](https://github.com/StartupsPoleEmploi/avril/blob/master/lib/vae/authorities/rncp/custom_rules.ex#L147)) :
  + 25520
  + 25522
  + 25471

## Certifications rendues inactives alors qu'elles sont actives au RNCP :

- les BEP
- les fiches de l'éducation nationale dont la fin de validité est définie à la fin de l'année en cours, à partir du mois de juillet.
- les ID RNCP suivants ([source](https://github.com/StartupsPoleEmploi/avril/blob/master/lib/vae/authorities/rncp/custom_rules.ex#L141)) :
  + 462
  + 4504
  + 5440
  + 31191
- les fiches de CCI France dont l'ID RNCP **n'est pas** parmis les suivants ([source](https://github.com/StartupsPoleEmploi/avril/blob/master/lib/vae/authorities/rncp/custom_rules.ex#L26)) :
  + 11200
  + 23827
  + 23869
  + 23872
  + 23932
  + 23937
  + 23939
  + 23940
  + 26901
  + 27095
  + 27096
  + 27365
  + 27413
  + 28669
  + 28764
  + 29535
  + 32362
  + 34353
  + 34928
  + 34965
  + 34999
  + 35001
  + 35010

## Certifications avec acronyme personnalisé BATC

- La fiche à l'ID RNCP 23909 ([source](https://github.com/StartupsPoleEmploi/avril/blob/master/lib/vae/authorities/rncp/custom_rules.ex#L117))