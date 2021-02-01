[SUJET]: # (<%= @username %> a annulé sa candidature pour le diplôme <%= @certification_name %> !)

Bonjour,

Afin de faciliter le suivi de vos dossiers, Avril vous informe que **<%= @username %>** vient
d'annuler sa candidature auprès de vos services pour la certification **<%= @certification_name %>**.

<%= if @meeting do %>
<%= @username %> s'était inscrit à la réunion d'information suivante:

- Date: <%= Timex.format!(@meeting.data.start_date, @date_format, :strftime) %>
- Lieu : <%= @meeting.data.place %>
- Adresse : <%= @meeting.data.address %> <%= @meeting.data.postal_code %>

Merci d'annuler cette inscription.
<% end %>

Nous restons à disposition pour tout complément d'information.

L'équipe Avril