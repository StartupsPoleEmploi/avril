# Félicitations pour votre projet VAE !

### Pour le diplôme <%= @certification_name %>

<%= if @meeting do %>
Votre inscription à la réunion d'information a bien été enregistrée :

- Date: <%= @meeting.date %>
- Adresse : <%= @meeting.place %>
- Tel: <%= @delegate_phone_number %>

<%= if @france_vae do %>
Surveillez votre boite mail, vous allez recevoir un email de confirmation de la part de notre partenaire France VAE.
<% end %>
<% else %>
Contactez dès maintenant votre centre <%= @delegate_phone_number %> ou <%= @delegate_email %> pour y rencontrer votre conseiller VAE !
<% end %>

Vous retrouverez dans votre profil les éléments transmis à votre centre VAE.

**[Voir mon profil](<%= @url %>)**

<%= @delegate_name %> a reçu un email l'informant de votre démarche. Il a accès à votre profil et vous a peut-être déjà envoyé un message. Vérifiez votre boite mail régulièrement !