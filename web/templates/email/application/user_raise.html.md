Bonjour <%= @user_name %>,

Vous souhaitez toujours obtenir votre <%= @certification_name %> en VAE ?

Obtenir ce diplôme à votre rythme et en 2020, c'est possible, voici <%= if @booklet_url, do: 3, else: 2 %> conseils d'Avril pour vous :

#### Contactez ou recontactez votre centre VAE

> <%= @delegate_name %>
> <%= @delegate_address %>
> Tel : <%= @delegate_phone_number %>

**[Je contact mon centre VAE par email](<%= @delegate_email %>)**

<%= if @booklet_url do %>
#### Remplissez votre dossier de candidature en ligne

Nous avons dématérialisé votre dossier de candidature.

**[Je remplis mon dossier](<%= @booklet_url %>)**
<% end %>


#### Financez votre VAE

Une VAE ça coûte combien ? Où trouver les financements ? Vous avez des questions sur le financement : celui-ci est prit en charge dans la majorité des cas.

**[En apprendre plus sur le financement](<%= @funding_url %>)**



Surtout n'attendez pas le printemps, si vous êtes perdus, [contactez notre équipe](contact@avril.pole-emploi.fr).

Bonne chance,

L'équipe Avril