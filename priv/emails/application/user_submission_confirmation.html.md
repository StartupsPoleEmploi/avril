[SUJET]: # (<%= @username %>, voici comment obtenir votre <%= @certification_name %>)

# Félicitations pour votre projet VAE !

### Pour le diplôme <%= @certification_name %>

<%= if @meeting do %>
Votre inscription à la réunion d'information a bien été enregistrée :

- Date: <%= Timex.format!(@meeting.start_date, @date_format, :strftime) %>
- Lieu : <%= @meeting.place %>
- Adresse : <%= @meeting.address %> <%= @meeting.postal_code %>
- Tel: <%= @delegate_phone_number %>

<% else %>
Contactez dès maintenant votre centre VAE au <%= @delegate_phone_number %> ou par email <%= @delegate_email %> pour être mis en relation avec votre conseiller VAE !
<% end %>

Vous retrouverez dans votre profil les éléments transmis à votre centre VAE.

**[Voir ma candidature](<%= @url %>)**

<%= if @is_france_vae do %>
Surveillez votre boite mail, vous allez recevoir un email de confirmation de la part de notre partenaire France VAE.
<% else %>
<%= @delegate_name %> a reçu un email l'informant de votre démarche. Il a accès à votre profil et vous a peut-être déjà envoyé un message. Vérifiez votre boite mail régulièrement !
<% end %>