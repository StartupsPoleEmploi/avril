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

Le centre vous apportera des précisions sur ses procédures internes et, les éléments de candidature saisis dans Avril faciliteront la suite de votre parcours.
<% end %>

Vous retrouverez ces éléments dans votre profil. Sachez aussi qu’ils ont  été transmis à votre centre VAE.

**[Voir ma candidature](<%= @url %>)**

<%= if @is_france_vae do %>
Surveillez votre boite mail, vous allez recevoir un email de confirmation de la part de notre partenaire France VAE.
<% else %>
<%= @delegate_name %> a reçu un email l'informant de votre démarche. Il a accès à votre profil et vous a peut-être déjà envoyé un message. Vérifiez votre boite mail régulièrement !
<% end %>

<%= if @is_afpa do %>
Votre certificateur propose des réunions d'information à la VAE.

**[Voir les réunions disponibles](https://www.afpa.fr/agenda?_rechercheevenementportlet_WAR_rechercheportlet_INSTANCE_4ONof6W5P5AJ_formDate=1599641591738&p_p_id=101_INSTANCE_agenda&_101_INSTANCE_agenda_afpa_ddm__22997__DateDebut_en_US=09%2F09%2F2020&_101_INSTANCE_agenda_afpa_ddm__22997__DateFin_en_US=&_101_INSTANCE_agenda_afpa_ddmStructureKey=EVENEMENT&_101_INSTANCE_agenda_categoryId=58334180&_101_INSTANCE_agenda_categoryId=&_rechercheevenementportlet_WAR_rechercheportlet_INSTANCE_4ONof6W5P5AJ_typeEvenement=58334180&_rechercheevenementportlet_WAR_rechercheportlet_INSTANCE_4ONof6W5P5AJ_region=&_rechercheevenementportlet_WAR_rechercheportlet_INSTANCE_4ONof6W5P5AJ_ville=&_rechercheevenementportlet_WAR_rechercheportlet_INSTANCE_4ONof6W5P5AJ_dateDebut=&_rechercheevenementportlet_WAR_rechercheportlet_INSTANCE_4ONof6W5P5AJ_dateFin=)**
<% end %>