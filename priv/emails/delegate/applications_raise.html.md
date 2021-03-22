[SUJET]: # (Vos candidats VAE – Avril – des 15 derniers jours !)

Bonjour <%= @delegate.name %>,

Ces 15 derniers jours, nous vous avons transmis <%= length @applications %> candidatures à la VAE. Vous pouvez consulter le profil, livret de recevabilité et les justificatifs de chaque candidat en cliquant sur les liens ci-dessous.

<ul>
  <%= for application <- @applications do %>
    <li><a href="<%= @link.(application) %>"><%= @label.(application) %></a></li>
  <% end %>
</ul>

Les candidats ont certifié exacte l'intégralité des renseignements fournis dans leur dossier de recevabilité.

Voilà de belles VAE en perspective !

> **Le saviez-vous?** 
>
> Vous pouvez modifier vos coordonnées connues d'Avril directement en cliquant sur l'une des candidatures ci-dessus.
>
> Voici les informations dont nous disposons actuellement :
> - Nom du contact : <%= @delegate.person_name %>
> - Adresse : <%= @delegate.address %>
> - Email : <%= @delegate.email %>
> - Tél : <%= @delegate.telephone %>
> - Site internet : <%= @delegate.website %>

Très bonne fin de journée à vous et à votre équipe.

L’équipe d’Avril