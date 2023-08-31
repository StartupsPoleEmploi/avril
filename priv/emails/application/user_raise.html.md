[SUJET]: # (<%= @username %> pour votre diplôme de <%= @certification_name %> en VAE)

Bonjour <%= @username %>,

Félicitations pour votre projet de VAE !

Je vous contacte suite à votre visite sur Avril, le diplôme <%= @certification_name %> vous intéresse toujours ?

<%= if @has_meetings_available do %>
La prochaine étape : rencontrer le spécialiste de ce diplôme en VAE. Il est proche de chez vous et organise régulièrement des réunions d’information. A la fin de cette réunion, vous saurez tout sur votre VAE et votre futur diplôme.

C’est parti ?

**[Choisir une réunion d’information proche de chez moi](<%= @application_url %>)**
<% else %>
La prochaine étape: transmettre votre candidature au spécialiste VAE pour ce diplôme proche de chez vous.

**[Terminer et transmettre ma candidature](<%= @application_url %>)**
<% end %>

Je vous souhaite une excellente fin de journée,

Marie de l’équipe Avril