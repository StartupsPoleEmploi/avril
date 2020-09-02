[SUJET]: # (<%= @username %> souhaite faire une VAE et attend un contact de votre part !)

# Bonjour,

### <%= @username %> souhaite démarrer une VAE pour le diplôme <%= @certification_name %>. Soutenez sa démarche !

Le service Avril l'a accompagné·e dans la complétion de son livret de recevabilité
<%= if @meeting do %> et à l'inscription à une réunion d'information <% end %>
mais nous savons qu'un candidat sur deux a besoin d'être encouragé dans son projet de VAE.

Le candidat a certifié exacte l'intégralité des renseignements fournis dans son dossier de recevabilité.

Nous vous invitons à consulter son profil et à le recontacter pour lui présenter votre procédure d’accès à la VAE.

**[Voir sa candidature et télécharger son dossier de recevabilité](<%= @url %>)**

<%= if @meeting do %>
En outre, <%= @username %> s'est positionné sur la réunion d'information :

- Date: <%= Timex.format!(@meeting.start_date, @date_format, :strftime) %>
- Lieu : <%= @meeting.place %>
- Adresse : <%= @meeting.address %> <%= @meeting.postal_code %>
<% end %>
