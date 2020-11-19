Prochaines étapes à suivre :

1. Téléchargez votre dossier puis imprimez-le.
2. N'oubliez pas de dater et signer le document à la fin.
3. Rassemblez les pièces justificatives, voir liste ci-après.
4. Envoyez le tout par voie postale à :

<%= if @application.delegate.process.booklet_address do %>
**<%= @application.delegate.process.booklet_address %>**
<% else %>
**<%= @application.delegate.name %>**<br /><%= @application.delegate.address_name %><br /><%= @application.delegate.address %>
<% end %>


Vous recevrez la réponse sous 2 mois maximum. Sachez que la loi stipule qu’une non-réponse au bout de 2 mois vaut accord, si votre dossier était complet.

---

#### Documents à fournir (photocopies, pas besoin de fournir les originaux) :

- Photocopie de carte nationale d’identité ou de passeport, en cours de validité ou périmés depuis moins de 5 ans ou carte de séjour en cours de validité
- Justificatif pour toutes les formations, ou diplômes que vous avez cités dans votre dossier
- Pour les emplois salariés, l’attestation employeur ou le certificat de travail avec vos 12 dernières fiches de paie
- Si vous avez des emplois non-salariés, l’attestation d’inscription auprès des organismes habilités et les justificatifs de la durée de cette inscription (registre du commerce ou des sociétés, registre des métiers, URSSAF ou tout autre document pouvant attester de votre activité professionnelle indépendante).

**[Voir l’ensemble des justificatifs pour toutes les situations](<%= @receipts_url %>)**