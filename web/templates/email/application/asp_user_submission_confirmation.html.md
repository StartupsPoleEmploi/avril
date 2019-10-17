# Félicitations pour votre démarche VAE !

### Vous avez choisi de valider le diplôme <%= @certification_name %> par la VAE.

La transmission de vos informations au centre VAE n'est malheureusement pas encore possible mais nous y travaillons activement !

<%= if @delegate_website do %>
En attendant, pour commencer votre démarche, nous vous invitons à créer votre dossier sur le site de l'ASP.

**[Créer mon dossier](<%= @delegate_website %>)**
<% end %>

Pour toute demande d'informations complémentaires, vous pouvez les contacter par téléphone ou par email.

- Nom du contact : <%= @delegate_person_name %>
- Tel : <%= @delegate_phone_number %>
- Email : <%= @delegate_email %>

# Nous vous souhaitons une totale réussite !

