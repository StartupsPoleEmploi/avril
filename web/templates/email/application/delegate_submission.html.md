# Bonjour,

### <%= @user_name %> a besoin de votre appel. Soutenez sa démarche de VAE !

Avril - la VAE Facile l'a informé des étapes à suivre (inscription en ligne ou à une réunion d'information, etc.) mais nous savons qu'un candidat sur deux a besoin d'être encouragé dans son projet de VAE.

**[Consulter son parcours](@url)**

<%= if @meeting do %>
<%= @user_name %> s'est positionné sur la réunion d'information :

- Date: <%= @meeting.date %>
- Adresse : <%= @meeting.place %>
<% end %>
