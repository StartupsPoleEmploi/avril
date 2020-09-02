[SUJET]: # (<%= @username %>, vous êtes inscrit à une réunion d'information)

# Félicitations,

### Vous êtes inscrits à une réunion d'information VAE pour le diplôme <%= @certification_name %>

Votre inscription a bien été enregistrée :

- Date: <%= Timex.format!(@meeting.start_date, @date_format, :strftime) %>
- Lieu : <%= @meeting.place %>
- Adresse : <%= @meeting.address %> <%= @meeting.postal_code %>
- Tel: <%= @delegate_phone_number %>

Nous comptons sur votre présence !

**[Voir mes rendez-vous](<%= @url %>)**
