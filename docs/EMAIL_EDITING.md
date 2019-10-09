# Editer les emails sur Avril

Certains emails sont éditables directement dans le code, au format markdown.

<!-- MarkdownTOC -->

- [Où se trouvent les fichiers ?](#o%C3%B9-se-trouvent-les-fichiers-)
- [Markdown générique](#markdown-g%C3%A9n%C3%A9rique)
  - [Paragraphe](#paragraphe)
  - [Gras & Italique](#gras--italique)
  - [Listes](#listes)
  - [Titres](#titres)
  - [Liens](#liens)
  - [Divers](#divers)
- [Markdown spécifique à Avril](#markdown-sp%C3%A9cifique-%C3%A0-avril)
  - [Call to action](#call-to-action)
  - [Variables](#variables)
  - [Conditions](#conditions)

<!-- /MarkdownTOC -->

## Où se trouvent les fichiers ?

Les fichiers sont situés dans le dossier [/web/templates/email](/web/templates/email). Les noms sont choisis pour être explicites et ne pas nécessiter plus d'explications.

## Markdown générique

Le [markdown](https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet) est un format de fichier qui permet de générer du texte riche de manière visuelle. L'objectif étant de maintenir la lisibilité du fichier en permanence.

Voici les différentes possibilités utiles ici qu'offre cette syntaxe :

### Paragraphe

```
Simple paragraphe de texte.
```

### Gras & Italique

Pour obtenir un contenu *en italique*, il suffit de l'entourer d'astérisques. _Entre underscore_ fonctionne aussi.

Pour obtenir un contenu **en gras**, il faut doubler les astérisques. __Entre double underscore__ fonctionne aussi.

```
Pour obtenir un contenu *en italique*, il suffit de l'entourer d'astérisques. _Entre underscore_ fonctionne aussi.

Pour obtenir un contenu **en gras**, il faut doubler les astérisques. __Entre double underscore__ fonctionne aussi.
```

### Listes

Liste non numérotée :

- élément
- autre élément
- et un autre

Liste numérotée :

1. élément
2. autre élément
3. et un autre

```
Liste non numérotée :

- élément
- autre élément
- et un autre

Liste numérotée :

1. élément
2. autre élément
3. et un autre
```

### Titres

```

Un titre avec # :

# Titre niveau 1

## Titre niveau 2

etc. jusque niveau 6
```

### Liens

Un lien s'écrit [Texte du lien](http://url-du-lien.com).

Et une image presque pareil: ![description de l'image](https://avril.pole-emploi.fr/images/avril-beta.svg "Titre de l'image")

```
Un lien s'écrit [Texte du lien](http://url-du-lien.com).

Et une image presque pareil: ![description de l'image](https://avril.pole-emploi.fr/images/avril-beta.svg "Titre de l'image")

```

### Divers

Un séparateur s'écrit `---`:

---

## Markdown spécifique à Avril

### Call to action

Pour générer un call-to-action dans un email:

![Call to action](assets/call-to-action.png), il faut mettre le lien en gras :

```
**[Je confirme mon email](http://lien-de-confirmation.com)**
```

### Variables

Pour afficher le contenu d'une variable branchée au préalable :

```
<%= @nom_de_la_variable %>
```

### Conditions

Pour mettre une condition dans le template :

```
<%= if @is_asp do %>
Il faut vous inscrire sur le site XXX.
<% else %>
Attendez d'être recontacté.
<% end %>
```

NB: Le `<% else %>` est facultatif.