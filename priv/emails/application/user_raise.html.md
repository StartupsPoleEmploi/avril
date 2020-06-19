[SUJET]: # (<%= @username %> pour votre diplôme de <%= @certification_name %> en VAE)

Bonjour <%= @username %>,

Félicitations pour votre projet de VAE !

<%= if @finish_booklet_todo do %>
Je vous contacte suite à votre candidature pour le diplôme <%= @certification_name %>.

J’ai constaté qu’elle n’était pas complète et qu’il manquait des justificatifs. Il n’est pas trop tard pour le faire.

Dès qu’elle sera terminée, vous pourrez la transmettre au certificateur et rencontrer un conseiller VAE spécialisé pour ce diplôme.

**[Terminer ma candidature](<%= @application_url %>)**
<% else %>
Je vous contacte suite à votre visite sur Avril, le diplôme <%= @certification_name %> vous intéresse toujours ?

La prochaine étape c’est le dossier de recevabilité qui ne vous prendra que quelques minutes et vous permettra de rencontrer le spécialiste VAE de votre diplôme, sans aucun engagement.

C’est parti ?
**[Compléter ma recevabilité](<%= @application_url %>)**
<% end %>

Je vous souhaite une excellente fin de journée,

Marie de l’équipe Avril