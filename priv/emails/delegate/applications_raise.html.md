[SUJET]: # (Vos candidats VAE – Avril – des 15 derniers jours !)

Bonjour <%= @delegate.name %>,

Ces 15 derniers jours, nous vous avons transmis <%= length @applications %> candidatures à la VAE. Vous pouvez consulter le profil, livret de recevabilité et les justificatifs de chaque candidat en cliquant sur les liens ci-dessous.

<ul>
  <%= for application <- @applications do %>
    <li><a href="<%= @link.(application) %>"><%= @label.(application) %></a></li>
  <% end %>
</ul>

Voilà de belles VAE en perspective !

Très bonne fin de journée à vous et à votre équipe.

L’équipe d’Avril