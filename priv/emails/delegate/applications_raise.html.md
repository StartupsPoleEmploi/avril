[SUJET]: # (Vos candidats VAE – Avril – des 15 derniers jours !)

Bonjour <%= @delegate.name %>,

Ces 15 derniers jours <%= length @applications %> utilisateurs d’Avril vous ont transmis une candidature pour les diplômes suivants :

<ul>
  <%= for application <- @applications do %>
    <li><a href="<%= @link.(application) %>"><%= @label.(application) %></a></li>
  <% end %>
</ul>

Vous pouvez consulter leur profil, livret de recevabilité et justificatifs en cliquant sur les liens ci-dessus.

Voilà de belles VAE en perspectives !

Très bonne fin de journée à vous et à votre équipe.

L’équipe d’Avril