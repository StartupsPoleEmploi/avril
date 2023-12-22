[SUJET]: # (N’attendez pas le mois d'avril pour contribuer au nouveau service public de la VAE ! L'équipe d’Avril vous souhaite une bonne année 2024)

<%= if @submitted_application_count > 0 do %>
Depuis le <%= Timex.format!(@start_date, @date_format, :strftime) %>, Avril est fière d'avoir orienté <%= @submitted_application_count %> candidatures à la VAE vers vos services. Ce sont vos diplômes qui ont eu du succès :

~~
<%= @popular_certifications_list %>
~~

Cela représente <%= @certifiers_application_count %>

Il vous reste un mois pour traiter les dernières candidatures. 
<% else %>
Depuis le 16/04/2019, Avril est fière d'avoir orienté <%= @certifiers_application_count %>

Pour savoir quelles sont les 10 diplômes les plus demandés en VAE :

_[Consulter les stats sur la VAE](https://avril.pole-emploi.fr/stats)_
<% end %>

Dès janvier, le nouveau service public de la VAE va donner un nouveau souffle à ce dispositif. Encore plus de femmes et d’hommes souhaiteront obtenir vos diplômes par la VAE.

Contribuez à la VAE rénovée en devenant Architecte Accompagnateur de parcours.

**[En savoir plus sur l'architecte accompagnateur de parcours en VAE](https://vae.gouv.fr/espace-professionnel/)**

Au moment d’arrêter le site Avril, nous vous adressons mille Mercis pour avoir aidé et accompagné ces validations d’acquis 🤝🏼.

Que 2024 vous apporte tout le bonheur que vous souhaitez et surtout beaucoup, beaucoup de belles VAE ! 

L'équipe d’Avril