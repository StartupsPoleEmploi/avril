# Bonjour,

### <%= @user_name %> souhaite démarrer une VAE pour le diplôme <%= @certification_name %>. Soutenez sa démarche !

Avril - la VAE Facile l'a informé des étapes à suivre (inscription en ligne ou à une réunion d'information, etc.) mais nous savons qu'un candidat sur deux a besoin d'être encouragé dans son projet de VAE.

**[Consulter son parcours](<%= @url %>)**

<%= if @meeting do %>
<%= @user_name %> s'est positionné sur la réunion d'information :

- Date: <%= Timex.format!(@meeting.start_date, @date_format, :strftime) %>
- Lieu : <%= @meeting.place %>
- Adresse : <%= @meeting.address %> <%= @meeting.postal_code %>
<% end %>
