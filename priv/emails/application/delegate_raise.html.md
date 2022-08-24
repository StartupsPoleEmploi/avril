[SUJET]: # (<%= @username %> est sans nouvelle de votre part pour sa candidature VAE)

Bonjour,

<%= @username %> a adressé sa candidature VAE pour un <%= @certification_name %> 
le <%= Timex.format!(@application.submitted_at, @date_format, :strftime) %> 
et il est sans nouvelle de votre part.

Merci de ne pas l'oublier

<%= if @has_booklet do %>
**[Voir sa candidature et télécharger son dossier de recevabilité](<%= @url %>)**
<% else %>
**[Voir sa candidature](<%= @url %>)**
<% end %>

Merci