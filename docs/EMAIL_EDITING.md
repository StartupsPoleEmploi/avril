# Editer les emails sur Avril

Certains emails sont éditables directement dans le code, au format markdown.

## Formattage Markdown

Le [markdown](https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet) est un format de fichier qui permet de générer du texte riche de manière visuelle. L'objectif étant de maintenir la lisibilité du fichier en permanence.

Voici les différentes possibilités utiles ici qu'offre cette syntaxe :

```


Simple paragraphe de texte.

Contenu avec *mots en italique* entre simple astérisque. _Mots entre underscore_ fonctionne aussi.

Contenu avec **mots en gras** entre double astérisque. __Mots entre double underscore__ fonctionne aussi.

Liste non numérotée :

- élément
- autre élément
- et un autre

Liste numérotée :

1. élément
2. autre élément
3. et un autre

Un séparateur s'écrit

---

Un titre avec # :

# Titre niveau 1

## Titre niveau 2

etc. jusque niveau 6

Un lien s'écrit [Texte du lien](http://url-du-lien.com).

Et une image presque pareil: ![description de l'image](https://url-de-limage.com/image.jpg "Titre de l'image")

```

## Markdown spécifique à Avril

### Call to action

Pour générer un call-to-action dans un email: ![Call to action](assets/call-to-action.png), il faut mettre le lien en gras :

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
<% if @is_asp do %>
Il faut vous inscrire sur le site XXX.
<% else %>
Attendez d'être recontacté.
<% end %>
```

NB: Le `<% else %>` est facultatif.

## Où se trouvent les fichiers :

Les fichiers sont situés dans le dossier [/web/templates/email](/web/templates/email). Les noms sont choisis pour être explicites et ne pas nécessiter plus d'explications.