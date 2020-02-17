Bonjour <%= @user_name %>,

Vous souhaitez toujours obtenir votre <%= @certification_name %> en VAE ?

Obtenir ce diplôme cette année et à votre rythme, c'est possible.
Voici <%= if @booklet_url, do: 3, else: 2 %> conseils d'Avril pour vous :

#### - Contactez ou recontactez votre centre VAE

> <%= @delegate_name %>
> <%= @delegate_address %>
> Tel : <%= @delegate_phone_number %>

**[Je contact mon centre VAE par email](mailto:<%= @delegate_email %>)**

<%= if @booklet_url do %>
#### - Remplissez votre dossier de candidature en ligne

Avec l'aide d'Avril, remplissez facilement votre dossier de recevabilité avant de l'envoyer à votre centre VAE.

**[Je remplis mon dossier](<%= @registration_url %>)**
<% end %>


#### - Financez votre VAE

Une VAE ça coûte combien ? Où trouver les financements ? Vous avez des questions sur le financement : celui-ci est prit en charge dans la majorité des cas.

**[En apprendre plus sur le financement](https://avril.pole-emploi.fr/financement-vae)**



Surtout n'attendez pas le printemps, si vous êtes perdus, [contactez notre équipe](contact@avril.pole-emploi.fr) !

Bonne chance,

L'équipe Avril
