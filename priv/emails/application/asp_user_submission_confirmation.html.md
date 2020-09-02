[SUJET]: # (<%= @username %>, voici comment obtenir votre <%= @certification_name %>)

# Félicitations pour votre démarche VAE !

### Vous avez choisi de valider le diplôme <%= @certification_name %> par la VAE.

La transmission de vos informations au centre VAE n'est malheureusement pas encore possible mais nous y travaillons activement !

<%= if @delegate_website do %>
En attendant, pour commencer votre démarche, nous vous invitons à créer votre dossier sur le site de l'ASP (c’est l’organisme qui traite les candidatures VAE pour le diplôme sélectionné, pour la France entière).

**[Créer mon dossier](<%= @delegate_website %>)**
<% end %>

Pour toute demande d'informations complémentaires, vous pouvez les contacter par téléphone.

- Nom du contact : <%= @delegate_person_name %>
- Tel : <%= @delegate_phone_number %>

Par la suite, vous pourrez vous rapprocher de votre conseiller Pôle emploi ou d’un [Point Relai Conseil](https://avril.pole-emploi.fr/point-relais-conseil-vae) de proximité pour identifier un accompagnateur à votre démarche VAE.

# Nous vous souhaitons une réussite totale !

