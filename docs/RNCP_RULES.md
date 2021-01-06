# Règles d'import RNCP

Le RNCP est le référentiel des diplômes disponibles. Nous alimentons la base d'Avril avec les
données qu'ils nous fournissent, sur la base d'un import régulier.

Toutefois, certaines données sont imprécises ou inexactes pour notre utilisation, aussi Avril
ajoute un ensemble de règles de gestion lors de l'import qui sont documentées ici-même.

## Le rapprochement des certifiers

Du fait qu'il n'existe pas de référentiel pour les institutions fournissant des diplômes, leurs noms
ne sont pas normalisés. Aussi il est nécessaire d'effectuer un rapprochement sur les noms avec notamment
pour règles :

- transformer les chiffres romains en chiffres arabes (`paris-vii == paris-7`)
- ignorer l'ordre des mots et certains mots de liaison (`université de Paris == Paris université`)
- permettre des imprécisions d'orthographe sauf pour les noms propres (`Vincennes != Vincenne`)

## Certifications ignorées (non importées dans Avril) :

- les fiches qui ne sont pas accessibles en VAE (`SI_JURY_VAE != "Oui"`)
- les fiches dont l'intitulé démarre par :
  + Un des meilleurs ouvriers de France
  + Ecole polytechnique

## Certifications associées à l'éducation nationale alors qu'elles ne le sont pas dans le RNCP :

- les fiches actives au RNCP associées au ministère de la solidarité
- les BTS au RNCP associées au ministère de l'enseignement suppérieur
- les ID RNCP suivants :
  + 4875
  + 4877
  + 34825
  + 34828

## Certifications dissociées de l'éducation nationale alors qu'elles le sont dans le RNCP :

- Les fiches avec l'un des acronymes suivants :
  + CQP
  + DEUST
  + DUT
  + MASTER
  + Licence Professionnelle
  + Titre ingénieur
- La fiche au RNCP ID 4505

## Certifications dissociées du ministère de la jeunesse, des sports et de la cohésion sociale alors qu'elle l'est dans le RNCP

- La fiche au RNCP ID 492

## Certifications rendues inactives alors qu'elles sont actives au RNCP :

- les BEP
- les fiches de l'éducation nationale dont la fin de validité est définie à la fin de l'année en cours, à partir du mois de juillet.
- les ID RNCP suivants :
  + 462
  + 4504
  + 5440
  + 31191
- les fiches de CCI France dont l'ID RNCP **n'est pas** parmis les suivants :
  + 28669
  + 23937
  + 23870
  + 27095
  + 27413
  + 23966
  + 23872
  + 26286
  + 16615
  + 28736
  + 23827
  + 26901
  + 27096
  + 32362
  + 23940
  + 29535
  + 27365
  + 28764
  + 23675
  + 23939
  + 23869
  + 23970
  + 28627
  + 23932

## Certifications avec acronyme personnalisé BATC

- La fiche à l'ID RNCP 23909

# Certifications avec un code ROME supplémentaire M1203

- La fiche à l'ID RNCP 4877