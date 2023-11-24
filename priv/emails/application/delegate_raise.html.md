[SUJET]: # (<%= @username %> est sans nouvelle de votre part pour sa candidature VAE)

Bonjour,

<%= @username %> a adressé sa candidature VAE pour un <%= @certification_name %> 
le <%= Timex.format!(@application.submitted_at, @date_format, :strftime) %> 
et il nous a demandé de vous envoyer ce message car il souhaite être recontacté.

Merci de ne pas l'oublier !

Attention **fermeture du site Avril** : Après le **31 décembre 2023**, plus aucun nouveau candidat Avril ! 
Au **31 janvier 2024**,  vous n’aurez plus accès à votre espace certificateur sur Avril. 
Vous ne pourrez donc plus lire à cette candidature.

<%= if @has_booklet do %>
**[Voir sa candidature et télécharger son dossier de recevabilité](<%= @url %>)**
<% else %>
**[Voir sa candidature](<%= @url %>)**
<% end %>

<%= if @user_phone do %>
NB: Pour des raisons techniques, 5% des emails ne parviennent pas à destination. Pourquoi ne pas essayer de contacter <%= @username %> par téléphone ? 

Son numéro : **<%= @user_phone %>**
<% end %>

Bien-à-vous,