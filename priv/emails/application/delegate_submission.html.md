[SUJET]: # (<%= @username %> souhaite faire une VAE et attend un contact de votre part !)

# Bonjour,

### <%= @username %> souhaite démarrer une VAE pour le diplôme <%= @certification_name %>. Soutenez sa démarche avant le 31 décembre 2023 !

Le service Avril l'a accompagné·e dans sa recherche de diplôme et de certificateur
mais nous savons qu'un candidat sur deux a besoin d'être encouragé dans son projet de VAE.

<%= if @has_booklet do %>
Le candidat a certifié exacte l'intégralité des renseignements fournis dans son dossier de recevabilité.
<% else %>
Le candidat n'a pas complété son dossier de recevabilité mais il est toujours temps de lui suggérer de
le faire sur Avril si vous le désirez.
<% end %>

Nous vous invitons à consulter son profil et à le recontacter pour lui présenter votre procédure d’accès à la VAE.

Attention **fermeture du site Avril** : Après le **31 décembre 2023**, plus aucun nouveau candidat Avril ! 
Au **31 janvier 2024**,  vous n’aurez plus accès à votre espace certificateur sur Avril. 
Vous ne pourrez donc plus lire à cette candidature.

<%= if @has_booklet do %>
**[Voir sa candidature et télécharger son dossier de recevabilité](<%= @url %>)**
<% else %>
**[Voir sa candidature](<%= @url %>)**
<% end %>