# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Vae.Repo.insert!(%Vae.SomeModel{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Vae.Repo
alias Vae.Rome
alias Vae.Profession
alias Vae.Certification
alias Vae.Certifier
alias Vae.Delegate
alias Vae.Delegate.Address
alias Vae.Delegate.Contact
alias Vae.Step

#DELETE ALL
delete_all = fn(model) ->
  Repo.all(model) |> Enum.each(&Repo.delete/1)
end

for model <- [Profession, Rome, Certification, Delegate, Certifier, Step], do: delete_all.(model)

#Steps
cava_idf_step1 = %Step{
  facultative: false,
  index: 1,
  title: "Réunion d'information",
  description: "Pour être conseillé-e et informé-e sur votre projet VAE",
  processes: [
    %Vae.Meta{
      description: "Inscription à une réunion",
      attachment: %Vae.Attachment{
        type: "link",
        target: "https://www.forpro-creteil.org/valider-acquis/inscription-reunion-information/"
      }
    }, %Vae.Meta{
      description: "Remplir le dossier parcours à remettre le jour de la réunion",
      attachment: %Vae.Attachment{
        type: "document",
        target: "http://documents.forpro-creteil.org/public/cava/descriptparcours.doc"
      }
    }, %Vae.Meta{
      description: "Prendre un rdv individuel de faisabilité avec votre CAVA"
    }
  ]
}

cava_idf_step2 = %Step{
  facultative: false,
  index: 2,
  title: "Demande de recevabilité (livret 1)",
  description: "Pour vérifier les conditions de recevabilité de votre demande",
  processes: [
    %Vae.Meta{
      description: "Remplir le livret 1",
      attachment: %Vae.Attachment{
        type: "document",
        target: "http://documents.forpro-creteil.org/public/cava/livret1.doc"
      }
    }, %Vae.Meta{
      description: "Renvoyer ou déposer votre Livret 1"
    }, %Vae.Meta{
      description: "Attendre la réponse de recevabilité"
    }, %Vae.Meta{
      description: "A réception de l’accord de recevabilité, demander au CAVA un contrat d’accompagnement et un devis pour l’accompagnement nominatif et personnalisé"
    }
  ]
}

cava_idf_step3 = %Step{
  facultative: true,
  index: 3,
  title: "Demande de financement de l'accompagnement",
  description: "Pour obtenir le financement de votre VAE par Pôle emploi et le Conseil Régional d'Ile de France",
  processes: [
    %Vae.Meta{
      title: "Faire une demande de financement de votre VAE à votre conseiller-e Pôle emploi",
      description: "Depuis pole-emploi.fr dans votre «espace personnel», dans la rubrique «mes échanges avec Pôle emploi» OU depuis l’application mobile dans la rubrique «contacter un conseiller»",
      attachment: %Vae.Attachment {
        type: "link",
        target: "https://candidat.pole-emploi.fr/candidat/espacepersonnel/authentification/"
      }
    }, %Vae.Meta{
      description: "Fournir votre accord de recevabilité + votre contrat d’accompagnement + votre devis d’accompagnement signé à votre conseiller-e qui se chargera d'envoyer la demande au Conseil Régional",
    }, %Vae.Meta{
      description: "Attendre l’accord de financement du Conseil Régional pour démarrer l’accompagnement. Vous le recevrez chez vous"
    }
  ],
  annexes: [
    %Vae.Meta{
      title: "Mail type",
      attachment: %Vae.Attachment{
        type: "document",
        target: "link to download documents"
      }
    }, %Vae.Meta{
      title: "Où trouver le mail de son conseiller-e",
      attachment: %Vae.Attachment{
        type: "document",
        target: "link to download documents"
      }
    }
  ]
}

cava_idf_step4 = %Step{
  facultative: true,
  index: 4,
  title: "Accompagnement (facultatif mais recommandé)",
  description: "Pour être aidé-e dans la rédaction du livret 2 et vous préparer au jury",
  processes: [
    %Vae.Meta{
      description: "Contacter votre CAVA pour l’informer de l’accord de financement et prendre votre 1er rdv d’accompagnement"
    }
  ]
}

cava_idf_step5 = %Step{
  facultative: false,
  index: 5,
  title: "Dossier d’expériences (Livret 2)",
  description: "Pour présenter vos expériences, vos compétences, votre environnement de travail et vos outils, en lien avec le référentiel du diplôme visé",
  processes: [
    %Vae.Meta{
      description: "Elaborer le livret 2",
      attachment: %Vae.Attachment{
        type: "document",
        target: "http://documents.forpro-creteil.org/public/cava/livret2.doc"
      }
    }, %Vae.Meta{
      description: "Remettre votre Livret 2 au CAVA lorsqu’il est finalisé"
    }, %Vae.Meta{
      description: "Inscription par le CAVA à l’examen"
    }
  ]
}

cava_idf_step6 = %Step{
  facultative: false,
  index: 6,
  title: "Passage devant le jury",
  description: "Pour soutenir votre livret 2 et le faire évaluer devant un jury constitué d’enseignants du diplôme et de professionnels du métier",
  processes: [
    %Vae.Meta{
      description: "Préparer cet oral avec votre conseiller-e en accompagnement VAE"
    }
  ]
}

cava_idf_step7 = %Step{
  facultative: false,
  index: 7,
  title: "Résultat",
  description: "Les résultats vous seront communiqués quelques semaines après l’oral. 3 situations possibles :",
  processes: [
    %Vae.Meta{
      description: "La réussite : Bravo !"
    }, %Vae.Meta{
      description: "La réussite partielle : Bravo, une partie de vos compétences est attestée et vous pouvez les compléter !"
    }, %Vae.Meta{
      description: "La non obtention : Rapprochez-vous de votre conseiller-e pour convenir de propositions adaptées"
    }
  ]
}

#Dava 78
dava_78_step1 = %Step{
  facultative: false,
  index: 1,
  title: "Réunion d'information",
  description: "Pour être conseillé-e et informé-e sur votre projet VAE",
  processes: [
    %Vae.Meta{
      description: "Demande d'inscription par mail",
      attachment: %Vae.Attachment{
        type: "mail",
        target: "dava@ac-versailles.fr"
      }
    }, %Vae.Meta{
      description: "Remplir le dossier parcours à remettre le jour de la réunion",
      attachment: %Vae.Attachment{
        type: "document",
        target: "http://cache.media.education.gouv.fr/file/aout2016/72/6/dava_2016_descriptif_parcours_diplomes_educ_nat_658726.pdf"
      }
    }, %Vae.Meta{
      description: "Prendre un rdv individuel de faisabilité avec votre DAVA"
    }
  ]
}

dava_78_step2 = %Step{
  facultative: false,
  index: 2,
  title: "Demande de recevabilité (livret 1)",
  description: "Pour vérifier les conditions de recevabilité de votre demande",
  processes: [
    %Vae.Meta{
      description: "Remplir le livret 1",
      attachment: %Vae.Attachment{
        type: "document",
        target: "http://cache.media.education.gouv.fr/file/2017/71/1/livret1V2017-300617_789711.pdf"
      }
    }, %Vae.Meta{
      description: "Renvoyer ou déposer votre Livret 1"
    }, %Vae.Meta{
      description: "Attendre la réponse de recevabilité"
    }, %Vae.Meta{
      description: "A réception de l’accord de recevabilité, demander au DAVA un contrat d’accompagnement et un devis pour l’accompagnement nominatif et personnalisé"
    }
  ]
}

dava_78_step3 = %Step{
  facultative: true,
  index: 3,
  title: "Demande de financement de l'accompagnement",
  description: "Pour obtenir le financement de votre VAE par Pôle emploi et le Conseil Régional d'Ile de France",
  processes: [
    %Vae.Meta{
      title: "Faire une demande de financement de votre VAE à votre conseiller-e Pôle emploi",
      description: "Depuis pole-emploi.fr dans votre «espace personnel», dans la rubrique «mes échanges avec Pôle emploi» OU depuis l’application mobile dans la rubrique «contacter un conseiller»",
      attachment: %Vae.Attachment {
        type: "link",
        target: "https://candidat.pole-emploi.fr/candidat/espacepersonnel/authentification/"
      }
    }, %Vae.Meta{
      description: "Fournir votre accord de recevabilité + votre contrat d’accompagnement + votre devis d’accompagnement signé à votre conseiller-e qui se chargera d'envoyer la demande au Conseil Régional",
    }, %Vae.Meta{
      description: "Attendre l’accord de financement du Conseil Régional pour démarrer l’accompagnement. Vous le recevrez chez vous"
    }
  ],
  annexes: [
    %Vae.Meta{
      title: "Mail type",
      attachment: %Vae.Attachment{
        type: "document",
        target: "link to download documents"
      }
    }, %Vae.Meta{
      title: "Où trouver le mail de son conseiller-e",
      attachment: %Vae.Attachment{
        type: "document",
        target: "link to download documents"
      }
    }
  ]
}

dava_78_step4 = %Step{
  facultative: true,
  index: 4,
  title: "Accompagnement (facultatif mais recommandé)",
  description: "Pour être aidé-e dans la rédaction du livret 2 et vous préparer au jury",
  processes: [
    %Vae.Meta{
      description: "Contacter votre DAVA pour l’informer de l’accord de financement et prendre votre 1er rdv d’accompagnement",
    }
  ]
}

dava_78_step5 = %Step{
  facultative: false,
  index: 5,
  title: "Dossier d’expériences (Livret 2)",
  description: "Pour présenter vos expériences, vos compétences, votre environnement de travail et vos outils, en lien avec le référentiel du diplôme visé",
  processes: [
    %Vae.Meta{
      description: "Elaborer le livret 2",
      attachment: %Vae.Attachment{
        type: "document",
        target: "http://cache.media.education.gouv.fr/file/2017/71/5/dava_2016_education_nationale_livret2_2017-300617_789715.pdf"
      }
    }, %Vae.Meta{
      description: "Remettre votre Livret 2 au DAVA lorsqu’il est finalisé"
    }, %Vae.Meta{
      description: "Inscription par le DAVA à l’examen"
    }
  ]
}

dava_78_step6 = %Step{
  facultative: false,
  index: 6,
  title: "Passage devant le jury",
  description: "Pour soutenir votre livret 2 et le faire évaluer, devant un jury constitué d’enseignants du diplôme et de professionnels du métier",
  processes: [
    %Vae.Meta{
      description: "Préparer cet oral avec votre conseiller-e en accompagnement VAE"
    }
  ]
}

dava_78_step7 = %Step{
  facultative: false,
  index: 7,
  title: "Résultat",
  description: "Les résultats vous seront communiqués quelques semaines après l’oral. 3 situations possibles :",
  processes: [
    %Vae.Meta{
      description: "La réussite : Bravo !"
    }, %Vae.Meta{
      description: "La réussite partielle : Bravo, une partie de vos compétences est attestée et vous pouvez les compléter !"
    }, %Vae.Meta{
      description: "La non obtention : rapprochez-vous de votre conseiller-e pour convenir de propositions adaptées"
    }
  ]
}

#Dava 75
dava_75_step1 = %Step{
  facultative: false,
  index: 1,
  title: "Réunion d'information",
  description: "Pour être conseillé-e et informé-e sur votre projet VAE",
  processes: [
    %Vae.Meta{
      description: "Inscription à une réunion",
      attachment: %Vae.Attachment{
        type: "link",
        target: "http://www.francevae.fr/francevae/lesacademies.php?ac=1"
      }
    },
    %Vae.Meta{
      description: "Prendre un rdv individuel de faisabilité avec votre DAVA"
    }
  ]
}

dava_75_step2 = %Step{
  facultative: false,
  index: 2,
  title: "Demande de recevabilité (livret 1)",
  description: "Pour vérifier les conditions de recevabilité de votre demande",
  processes: [
    %Vae.Meta{
      description: "Remplir le livret 1",
      attachment: %Vae.Attachment{
        type: "document",
        target: "http://gipfcip.scola.ac-paris.fr/vae/spip.php?action=acceder_document&arg=89&cle=a7d10e6876f6c6e3c34d7d593f0a240786d3c7a5&file=doc%2Flivret_1_demande_vae_03062016.doc"
      }
    }, %Vae.Meta{
      description: "Renvoyer ou déposer votre Livret 1"
    }, %Vae.Meta{
      description: "Attendre la réponse de recevabilité"
    }, %Vae.Meta{
      description: "A réception de l’accord de recevabilité, demander au DAVA un contrat d’accompagnement et un devis pour l’accompagnement nominatif et personnalisé"
    }
  ]
}

dava_75_step3 = %Step{
  facultative: true,
  index: 3,
  title: "Demande de financement de l'accompagnement",
  description: "Pour obtenir le financement de votre VAE par Pôle emploi et le Conseil Régional d'Ile de France",
  processes: [
    %Vae.Meta{
      title: "Faire une demande de financement de votre VAE à votre conseiller-e Pôle emploi",
      description: "Depuis pole-emploi.fr dans votre «espace personnel», dans la rubrique «mes échanges avec Pôle emploi» OU depuis l’application mobile dans la rubrique «contacter un conseiller»",
      attachment: %Vae.Attachment {
        type: "link",
        target: "https://candidat.pole-emploi.fr/candidat/espacepersonnel/authentification/"
      }
    }, %Vae.Meta{
      description: "Fournir votre accord de recevabilité + votre contrat d’accompagnement + votre devis d’accompagnement signé à votre conseiller-e qui se chargera d'envoyer la demande au Conseil Régional",
    }, %Vae.Meta{
      description: "Attendre l’accord de financement du Conseil Régional pour démarrer l’accompagnement. Vous le recevrez chez vous"
    }
  ],
  annexes: [
    %Vae.Meta{
      title: "Mail type",
      attachment: %Vae.Attachment{
        type: "document",
        target: "link to download documents"
      }
    }, %Vae.Meta{
      title: "Où trouver le mail de son conseiller-e",
      attachment: %Vae.Attachment{
        type: "document",
        target: "link to download documents"
      }
    }
  ]
}

dava_75_step4 = %Step{
  facultative: true,
  index: 4,
  title: "Accompagnement (facultatif mais recommandé)",
  description: "Pour être aidé-e dans la rédaction du livret 2 et vous préparer au jury",
  processes: [
    %Vae.Meta{
      description: "Contacter votre DAVA pour l’informer de l’accord de financement et prendre votre 1er rdv d’accompagnement",
    }
  ]
}

dava_75_step5 = %Step{
  facultative: false,
  index: 5,
  title: "Dossier d’expériences (Livret 2)",
  description: "Pour présenter vos expériences, vos compétences, votre environnement de travail et vos outils, en lien avec le référentiel du diplôme visé",
  processes: [
    %Vae.Meta{
      description: "Elaborer le livret 2",
      attachment: %Vae.Attachment{
        type: "document",
        target: "http://gipfcip.scola.ac-paris.fr/vae/spip.php?action=acceder_document&arg=88&cle=669ddd5eb2a83ccf3fd5d0fad680faf8cd134592&file=doc%2Flivret2vae22102015.doc"
      }
    }, %Vae.Meta{
      description: "Remettre votre Livret 2 au DAVA lorsqu’il est finalisé"
    }, %Vae.Meta{
      description: "Inscription par le DAVA à l’examen"
    }
  ]
}

dava_75_step6 = %Step{
  facultative: false,
  index: 6,
  title: "Passage devant le jury",
  description: "Pour soutenir votre livret 2 et le faire évaluer, devant un jury constitué d’enseignants du diplôme et de professionnels du métier",
  processes: [
    %Vae.Meta{
      description: "Préparer cet oral avec votre conseiller-e en accompagnement VAE"
    }
  ]
}

dava_75_step7 = %Step{
  facultative: false,
  index: 7,
  title: "Résultat",
  description: "Les résultats vous seront communiqués quelques semaines après l’oral. 3 situations possibles :",
  processes: [
    %Vae.Meta{
      description: "La réussite : Bravo !"
    }, %Vae.Meta{
      description: "La réussite partielle : Bravo, une partie de vos compétences est attestée et vous pouvez les compléter !"
    }, %Vae.Meta{
      description: "La non obtention : Rapprochez-vous de votre conseiller-e pour convenir de propositions adaptées"
    }
  ]
}

#ASP
asp_step1 = %Step{
  facultative: false,
  index: 1,
  title: "Contacter l’ASP",
  description: "Pour être informé-e sur votre projet VAE du secteur sanitaire et social et recevoir vos documents",
  processes: [
    %Vae.Meta{
      description: "Par téléphone au 0810.017.710 (0,06€ / min + prix d'un appel)"
    }, %Vae.Meta{
      description: "Par internet",
      attachment: %Vae.Attachment{
        type: "link",
        target: "http://vae.asp-public.fr"
      }
    }, %Vae.Meta{
      description: "Par courrier : ASP- UNACESS, 15 rue Léon walras - CS 70902 - 87017 Limoges cedex"
    }
  ]
}

asp_step2 = %Step{
  facultative: false,
  index: 2,
  title: "Demande de recevabilité (livret 1)",
  description: "Pour vérifier les conditions de recevabilité de votre demande",
  processes: [
    %Vae.Meta{
      description: "Remplir le livret 1",
      attachment: %Vae.Attachment{
        type: "link",
        target: "http://vae.asp-public.fr/"
      }
    }, %Vae.Meta{
      description: "Renvoyer votre Livret 1 à l’ASP"
    }, %Vae.Meta{
      description: "Attendre la réponse de recevabilité. La recevabilité est valable 3 ans"
    }
  ]
}

asp_step3 = %Step{
  facultative: false,
  index: 3,
  title: "Identifier votre organisme d’accompagnement référencé",
  description: "Pour solliciter un accompagnement de votre VAE",
  processes: [
    %Vae.Meta{
      title: "Si vous avez identifié un organisme accompagnateur VAE pour le DEAS, faites-vous confirmer qu’il est bien référencé par la région IDF",
      description: "L’organisme peut vous le confirmer sinon, vous pouvez faire cette demande à votre conseiller-e Pôle emploi depuis pole-emploi.fr dans votre «espace personnel», dans la rubrique «mes échanges avec Pôle emploi» OU depuis l’application mobile dans la rubrique «contacter un conseiller»"
    }, %Vae.Meta{
      title: "Si vous n’avez pas identifié d’organisme accompagnateur",
      description: "Adresser une demande à votre conseiller-e Pôle emploi depuis pole-emploi.fr dans votre «espace personnel», dans la rubrique «mes échanges avec Pôle emploi» OU depuis l’application mobile dans la rubrique «contacter un conseiller»"
    }, %Vae.Meta{
      title: "Contacter l’organisme accompagnateur retenu et lui demander un devis et un contrat d’accompagnement nominatifs et personnalisés"
    }
  ]
}

asp_step4 = %Step{
  facultative: false,
  index: 4,
  title: "Demande de financement de l'accompagnement",
  description: "Pour obtenir le financement de votre VAE par Pôle emploi et le Conseil Régional d'Ile de France",
  processes: [
    %Vae.Meta{
      title: "Faire une demande de financement de votre VAE à votre conseiller-e Pôle emploi",
      description: "Depuis pole-emploi.fr dans votre «espace personnel», dans la rubrique «mes échanges avec Pôle emploi» OU depuis l’application mobile dans la rubrique «contacter un conseiller»",
      attachment: %Vae.Attachment{
        type: "link",
        target: "https://candidat.pole-emploi.fr/candidat/espacepersonnel/authentification/"
      }
    }, %Vae.Meta{
      description: "Fournir votre accord de recevabilité + votre contrat d’accompagnement + votre devis d’accompagnement signé à votre conseiller-e qui se chargera d'envoyer la demande au Conseil Régional"
    }, %Vae.Meta{
      description: "Attendre l’accord de financement du Conseil Régional pour démarrer l’accompagnement. Vous le recevrez chez vous"
    }
  ]
}

asp_step5 = %Step{
  facultative: false,
  index: 5,
  title: "Accompagnement (facultatif mais recommandé)",
  description: "Pour être aidé-e dans la rédaction du livret 2 et vous préparer au jury",
  processes: [
    %Vae.Meta{
      description: "Contacter votre organisme accompagnateur pour l’informer de l’accord de financement et prendre votre 1er rdv d’accompagnement"
    }
  ]
}

asp_step6 = %Step{
  facultative: false,
  index: 6,
  title: "Dossier d’expériences (Livret 2)",
  description: "Pour présenter vos expériences, vos compétences, votre environnement de travail et vos outils, en lien avec le référentiel du diplôme visé",
  processes: [
    %Vae.Meta{
      description: "Elaborer le livret 2",
      attachment: %Vae.Attachment{
        type: "link",
        target: "http://vae.asp-public.fr/"
      }
    }, %Vae.Meta{
      description: "Retourner votre Livret 2 à l’ASP lorsqu’il est finalisé"
    }
  ]
}

asp_step7 = %Step{
  facultative: false,
  index: 7,
  title: "Passage devant le jury",
  description: "Pour soutenir votre livret 2 et le faire évaluer, devant un jury constitué d’enseignant du diplôme et de professionnels du métier",
  processes: [
    %Vae.Meta{
      description: "Se présenter sur entretien avec un jury dans la région de votre domicile"
    }, %Vae.Meta{
      description: "Préparer cet oral avec votre conseiller-e en accompagnement VAE"
    }
  ]
}

asp_step8 = %Step{
  facultative: false,
  index: 8,
  title: "Résultat",
  description: "Les résultats vous seront communiqués, par courrier,  quelques semaines après l’oral. 3 situations possibles",
  processes: [
    %Vae.Meta{
      description: "La réussite : Bravo !"
    }, %Vae.Meta{
      description: "La réussite partielle : Bravo, une partie de vos compétences est attestée et vous pouvez les compléter !"
    }, %Vae.Meta{
      description: "Non obtention : Rapprochez-vous de votre conseiller-e pour convenir de propositions adaptées et rebondir"
    }
  ]
}

#AFPA
afpa_75_93_step1 = %Step{
  facultative: false,
  index: 1,
  title: "Réunion d’information",
  description: "Pour être conseillé-e et informé-e sur votre projet VAE et vous faire remettre votre dossier de demande de VAE",
  processes: [
    %Vae.Meta{
      description: "Adresser un mail au référent VAE AFPA de votre département pour être inscrit-e à une réunion VAE",
      attachment: %Vae.Attachment{
        type: "mail",
        target: "cecile.laumonier@afpa.fr"
      }
    }, %Vae.Meta{
      description: "Bénéficier d'un entretien individuel en fin de réunion pour identifier ou confirmer votre projet"
    }, %Vae.Meta{
      description: "Vous faire remettre sur place, le dossier de demande de VAE et coordonnées de la DIRECCTE dont vous dépendez"
    }
  ]
}

afpa_92_step1 = %Step{
  facultative: false,
  index: 1,
  title: "Réunion d’information",
  description: "Pour être conseillé-e et informé-e sur votre projet VAE et vous faire remettre votre dossier de demande de VAE",
  processes: [
    %Vae.Meta{
      description: "Adresser un mail au référent VAE AFPA de votre département pour être inscrit-e à une réunion VAE",
      attachment: %Vae.Attachment{
        type: "mail",
        target: "myriam.claude@afpa.fr"
      }
}, %Vae.Meta{
      description: "Bénéficier d'un entretien individuel en fin de réunion pour identifier ou confirmer votre projet"
}, %Vae.Meta{
      description: "Vous faire remettre sur place, le dossier de demande de VAE et coordonnées de la DIRECCTE"
}
  ]
}

afpa_77_step1 = %Step{
  facultative: false,
  index: 1,
  title: "Réunion d’information",
  description: "Pour être conseillé-e et informé-e sur votre projet VAE et vous faire remettre votre dossier de demande de VAE",
  processes: [
    %Vae.Meta{
      description: "Adresser un mail au référent VAE AFPA de votre département pour être inscrit-e à une réunion VAE",
      attachment: %Vae.Attachment{
        type: "mail",
        target: "veronique.harrouin@afpa.fr"
      }
    }, %Vae.Meta{
      description: "Bénéficier d'un entretien individuel en fin de réunion pour identifier ou confirmer votre projet"
    }, %Vae.Meta{
      description: "Vous faire remettre sur place, le dossier de demande de VAE et coordonnées de la DIRECCTE"
    }
  ]
}

afpa_78_step1 = %Step{
  facultative: false,
  index: 1,
  title: "Réunion d’information",
  description: "Pour être conseillé-e et informé-e sur votre projet VAE et vous faire remettre votre dossier de demande de VAE",
  processes: [
    %Vae.Meta{
      description: "Adresser un mail au référent VAE AFPA de votre département pour être inscrit-e à une réunion VAE",
      attachment: %Vae.Attachment{
        type: "mail",
        target: "sophie.gazon@afpa.fr"
      }
    }, %Vae.Meta{
      description: "Bénéficier d'un entretien individuel en fin de réunion pour identifier ou confirmer votre projet"
    }, %Vae.Meta{
      description: "Vous faire remettre sur place, le dossier de demande de VAE et coordonnées de la DIRECCTE"
    }
  ]
}

afpa_91_step1 = %Step{
  facultative: false,
  index: 1,
  title: "Réunion d’information",
  description: "Pour être conseillé-e et informé-e sur votre projet VAE et vous faire remettre votre dossier de demande de VAE",
  processes: [
    %Vae.Meta{
      description: "Adresser un mail au référent VAE AFPA de votre département pour être inscrit-e à une réunion VAE",
      attachment: %Vae.Attachment{
        type: "mail",
        target: "laurence.taton@afpa.fr"
      }
    }, %Vae.Meta{
      description: "Bénéficier d'un entretien individuel en fin de réunion pour identifier ou confirmer votre projet"
    }, %Vae.Meta{
      description: "Vous faire remettre sur place, le dossier de demande de VAE et coordonnées de la DIRECCTE"
    }
  ]
}

afpa_94_step1 = %Step{
  facultative: false,
  index: 1,
  title: "Réunion d’information",
  description: "Pour être conseillé-e et informé-e sur votre projet VAE et vous faire remettre votre dossier de demande de VAE",
  processes: [
    %Vae.Meta{
      description: "Adresser un mail au référent VAE AFPA de votre département pour être inscrit-e à une réunion VAE",
      attachment: %Vae.Attachment{
        type: "mail",
        target: "catherine.deguglielmi@afpa.fr"
      }
    }, %Vae.Meta{
      description: "Bénéficier d'un entretien individuel en fin de réunion pour identifier ou confirmer votre projet"
    }, %Vae.Meta{
      description: "Vous faire remettre sur place, le dossier de demande de VAE et coordonnées de la DIRECCTE"
    }
  ]
}

afpa_95_step1 = %Step{
  facultative: false,
  index: 1,
  title: "Réunion d’information",
  description: "Pour être conseillé-e et informé-e sur votre projet VAE et vous faire remettre votre dossier de demande de VAE",
  processes: [
    %Vae.Meta{
      description: "Adresser un mail au référent VAE AFPA de votre département pour être inscrit-e à une réunion VAE",
      attachment: %Vae.Attachment{
        type: "mail",
        target: "samia.houmous@afpa.fr"
      }
    }, %Vae.Meta{
      description: "Bénéficier d'un entretien individuel en fin de réunion pour identifier ou confirmer votre projet"
    }, %Vae.Meta{
      description: "Vous faire remettre sur place, le dossier de demande de VAE et coordonnées de la DIRECCTE"
    }
  ]
}

afpa_75_93_step2 = %Step{
  facultative: false,
  index: 2,
  title: "Demande de recevabilité (livret 1)",
  description: "Pour vérifier les conditions de recevabilité de votre demande",
  processes: [
    %Vae.Meta{
      description: "Remplir le dossier de demande de VAE (livret 1)",
      attachment: %Vae.Attachment{
        type: "document",
        target: "http://travail-emploi.gouv.fr/demarches-et-fiches-pratiques/formulaires-et-teledeclarations/jeunes-actifs-et-actifs-en-formation/article/demande-de-validation-des-acquis-de-l-experience-vae"
      }
    }, %Vae.Meta{
      description: "Renvoyer ce dossier à la DIRECCTE de votre département",
      attachment: %Vae.Attachment{
        type: "link",
        target: "http://idf.direccte.gouv.fr/Adresses-et-horaires"
      }
    }, %Vae.Meta{
      description: "Attendre la réponse de recevabilité et l’envoi du dossier professionnel (livret 2)"
    }, %Vae.Meta{
      description: "A réception de l’accord de recevabilité, demander à l’AFPA un contrat d’accompagnement et un devis pour l’accompagnement nominatif et personnalisé."
    }
  ]
}

afpa_92_step2 = %Step{
  facultative: false,
  index: 2,
  title: "Demande de recevabilité (livret 1)",
  description: "Pour vérifier les conditions de recevabilité de votre demande",
  processes: [
    %Vae.Meta{
      description: "Remplir le dossier de demande de VAE (livret 1)",
      attachment: %Vae.Attachment{
        type: "document",
        target: "http://travail-emploi.gouv.fr/demarches-et-fiches-pratiques/formulaires-et-teledeclarations/jeunes-actifs-et-actifs-en-formation/article/demande-de-validation-des-acquis-de-l-experience-vae"
      }
    }, %Vae.Meta{
      description: "Renvoyer ce dossier à la DIRECCTE de votre département",
      attachment: %Vae.Attachment{
        type: "link",
        target: "http://idf.direccte.gouv.fr/Adresses-et-horaires"
      }
    }, %Vae.Meta{
      description: "Attendre la réponse de recevabilité et l’envoi du dossier professionnel (livret 2)"
    }, %Vae.Meta{
      description: "A réception de l’accord de recevabilité, demander à l’AFPA un contrat d’accompagnement et un devis pour l’accompagnement nominatif et personnalisé."
    }
  ]
}

afpa_77_step2 = %Step{
  facultative: false,
  index: 2,
  title: "Demande de recevabilité (livret 1)",
  description: "Pour vérifier les conditions de recevabilité de votre demande",
  processes: [
    %Vae.Meta{
      description: "Remplir le dossier de demande de VAE (livret 1)",
      attachment: %Vae.Attachment{
        type: "document",
        target: "http://travail-emploi.gouv.fr/demarches-et-fiches-pratiques/formulaires-et-teledeclarations/jeunes-actifs-et-actifs-en-formation/article/demande-de-validation-des-acquis-de-l-experience-vae"
      }
    }, %Vae.Meta{
      description: "Renvoyer ce dossier à la DIRECCTE de votre département",
      attachment: %Vae.Attachment{
        type: "link",
        target: "http://idf.direccte.gouv.fr/Adresses-et-horaires"
      }
    }, %Vae.Meta{
      description: "Attendre la réponse de recevabilité et l’envoi du dossier professionnel (livret 2)"
    }, %Vae.Meta{
      description: "A réception de l’accord de recevabilité, demander à l’AFPA un contrat d’accompagnement et un devis pour l’accompagnement nominatif et personnalisé."
    }
  ]
}

afpa_78_step2 = %Step{
  facultative: false,
  index: 2,
  title: "Demande de recevabilité (livret 1)",
  description: "Pour vérifier les conditions de recevabilité de votre demande",
  processes: [
    %Vae.Meta{
      description: "Remplir le dossier de demande de VAE (livret 1)",
      attachment: %Vae.Attachment{
        type: "document",
        target: "http://travail-emploi.gouv.fr/demarches-et-fiches-pratiques/formulaires-et-teledeclarations/jeunes-actifs-et-actifs-en-formation/article/demande-de-validation-des-acquis-de-l-experience-vae"
      }
    }, %Vae.Meta{
      description: "Renvoyer ce dossier à la DIRECCTE de votre département",
      attachment: %Vae.Attachment{
        type: "link",
        target: "http://idf.direccte.gouv.fr/Adresses-et-horaires"
      }
    }, %Vae.Meta{
      description: "Attendre la réponse de recevabilité et l’envoi du dossier professionnel (livret 2)"
    }, %Vae.Meta{
      description: "A réception de l’accord de recevabilité, demander à l’AFPA un contrat d’accompagnement et un devis pour l’accompagnement nominatif et personnalisé."
    }
  ]
}

afpa_91_step2 = %Step{
  facultative: false,
  index: 2,
  title: "Demande de recevabilité (livret 1)",
  description: "Pour vérifier les conditions de recevabilité de votre demande",
  processes: [
    %Vae.Meta{
      description: "Remplir le dossier de demande de VAE (livret 1)",
      attachment: %Vae.Attachment{
        type: "document",
        target: "http://travail-emploi.gouv.fr/demarches-et-fiches-pratiques/formulaires-et-teledeclarations/jeunes-actifs-et-actifs-en-formation/article/demande-de-validation-des-acquis-de-l-experience-vae"
      }
    }, %Vae.Meta{
      description: "Renvoyer ce dossier à la DIRECCTE de votre département",
      attachment: %Vae.Attachment{
        type: "link",
        target: "http://idf.direccte.gouv.fr/Adresses-et-horaires"
      }
    }, %Vae.Meta{
      description: "Attendre la réponse de recevabilité et l’envoi du dossier professionnel (livret 2)"
    }, %Vae.Meta{
      description: "A réception de l’accord de recevabilité, demander à l’AFPA un contrat d’accompagnement et un devis pour l’accompagnement nominatif et personnalisé."
    }
  ]
}

afpa_94_step2 = %Step{
  facultative: false,
  index: 2,
  title: "Demande de recevabilité (livret 1)",
  description: "Pour vérifier les conditions de recevabilité de votre demande",
  processes: [
    %Vae.Meta{
      description: "Remplir le dossier de demande de VAE (livret 1)",
      attachment: %Vae.Attachment{
        type: "document",
        target: "http://travail-emploi.gouv.fr/demarches-et-fiches-pratiques/formulaires-et-teledeclarations/jeunes-actifs-et-actifs-en-formation/article/demande-de-validation-des-acquis-de-l-experience-vae"
      }
    }, %Vae.Meta{
      description: "Renvoyer ce dossier à la DIRECCTE de votre département",
      attachment: %Vae.Attachment{
        type: "link",
        target: "http://idf.direccte.gouv.fr/Adresses-et-horaires"
      }
    }, %Vae.Meta{
      description: "Attendre la réponse de recevabilité et l’envoi du dossier professionnel (livret 2)"
    }, %Vae.Meta{
      description: "A réception de l’accord de recevabilité, demander à l’AFPA un contrat d’accompagnement et un devis pour l’accompagnement nominatif et personnalisé."
    }
  ]
}

afpa_95_step2 = %Step{
  facultative: false,
  index: 2,
  title: "Demande de recevabilité (livret 1)",
  description: "Pour vérifier les conditions de recevabilité de votre demande",
  processes: [
    %Vae.Meta{
      description: "Remplir le dossier de demande de VAE (livret 1)",
      attachment: %Vae.Attachment{
        type: "document",
        target: "http://travail-emploi.gouv.fr/demarches-et-fiches-pratiques/formulaires-et-teledeclarations/jeunes-actifs-et-actifs-en-formation/article/demande-de-validation-des-acquis-de-l-experience-vae"
      }
    }, %Vae.Meta{
      description: "Renvoyer ce dossier à la DIRECCTE de votre département",
      attachment: %Vae.Attachment{
        type: "link",
        target: "http://idf.direccte.gouv.fr/Adresses-et-horaires"
      }
    }, %Vae.Meta{
      description: "Attendre la réponse de recevabilité et l’envoi du dossier professionnel (livret 2)"
    }, %Vae.Meta{
      description: "A réception de l’accord de recevabilité, demander à l’AFPA un contrat d’accompagnement et un devis pour l’accompagnement nominatif et personnalisé."
    }
  ]
}

afpa_75_93_step3 = %Step{
  facultative: false,
  index: 3,
  title: "Demande de financement de l'accompagnement",
  description: "Pour obtenir le financement de votre VAE par Pôle emploi et le Conseil Régional d'Ile de France",
  processes: [
    %Vae.Meta{
      title: "Faire une demande de financement de votre VAE à votre conseiller-e Pôle emploi",
      description: "Depuis pole-emploi.fr dans votre «espace personnel», dans la rubrique «mes échanges avec Pôle emploi» OU depuis l’application mobile dans la rubrique «contacter un conseiller»",
      attachment: %Vae.Attachment{
        type: "link",
        target: "https://candidat.pole-emploi.fr/candidat/espacepersonnel/authentification/"
      }
    }, %Vae.Meta{
      description: "Fournir votre accord de recevabilité + votre contrat d’accompagnement + votre devis d’accompagnement signé à votre conseiller-e qui se chargera d'envoyer la demande au Conseil Régional'"
    }, %Vae.Meta{
      description: "Attendre l’accord de financement du Conseil Régional pour démarrer l’accompagnement, vous le recevrez chez vous"
    }
  ]
}

afpa_92_step3 = %Step{
  facultative: false,
  index: 3,
  title: "Demande de financement de l'accompagnement",
  description: "Pour obtenir le financement de votre VAE par Pôle emploi et le Conseil Régional d'Ile de France",
  processes: [
    %Vae.Meta{
      title: "Faire une demande de financement de votre VAE à votre conseiller-e Pôle emploi",
      description: "Depuis pole-emploi.fr dans votre «espace personnel», dans la rubrique «mes échanges avec Pôle emploi» OU depuis l’application mobile dans la rubrique «contacter un conseiller»"
    }, %Vae.Meta{
      description: "Fournir votre accord de recevabilité + votre contrat d’accompagnement + votre devis d’accompagnement signé à votre conseiller-e qui se chargera d'envoyer la demande au Conseil Régional"
    }, %Vae.Meta{
      description: "Attendre l’accord de financement du Conseil Régional pour démarrer l’accompagnement, vous le recevrez chez vous"
    }
  ]
}

afpa_77_step3 = %Step{
  facultative: false,
  index: 3,
  title: "Demande de financement de l'accompagnement",
  description: "Pour obtenir le financement de votre VAE par Pôle emploi et le Conseil Régional d'Ile de France",
  processes: [
    %Vae.Meta{
      title: "Faire une demande de financement de votre VAE à votre conseiller-e Pôle emploi",
      description: "Depuis pole-emploi.fr dans votre «espace personnel», dans la rubrique «mes échanges avec Pôle emploi» OU depuis l’application mobile dans la rubrique «contacter un conseiller»",
      attachment: %Vae.Attachment{
        type: "link",
        target: "https://candidat.pole-emploi.fr/candidat/espacepersonnel/authentification/"
      }
    }, %Vae.Meta{
      description: "Fournir votre accord de recevabilité + votre contrat d’accompagnement + votre devis d’accompagnement signé à votre conseiller-e qui se chargera d'envoyer la demande au Conseil Régional"
    },  %Vae.Meta{
      description: "Attendre l’accord de financement du Conseil Régional pour démarrer l’accompagnement, vous le recevrez chez vous"
    }
  ]
}

afpa_78_step3 = %Step{
  facultative: false,
  index: 3,
  title: "Demande de financement de l'accompagnement",
  description: "Pour obtenir le financement de votre VAE par Pôle emploi et le Conseil Régional d'Ile de France",
  processes: [
    %Vae.Meta{
      title: "Faire une demande de financement de votre VAE à votre conseiller-e Pôle emploi",
      description: "Depuis pole-emploi.fr dans votre «espace personnel», dans la rubrique «mes échanges avec Pôle emploi» OU depuis l’application mobile dans la rubrique «contacter un conseiller»",
      attachment: %Vae.Attachment{
        type: "link",
        target: "https://candidat.pole-emploi.fr/candidat/espacepersonnel/authentification/"
      }
    }, %Vae.Meta{
      description: "Fournir votre accord de recevabilité + votre contrat d’accompagnement + votre devis d’accompagnement signé à votre conseiller-e qui se chargera d'envoyer la demande au Conseil Régional"
    }, %Vae.Meta{
      description: "Attendre l’accord de financement du Conseil Régional pour démarrer l’accompagnement, vous le recevrez chez vous"
    }
  ]
}

afpa_91_step3 = %Step{
  facultative: false,
  index: 3,
  title: "Demande de financement de l'accompagnement",
  description: "Pour obtenir le financement de votre VAE par Pôle emploi et le Conseil Régional d'Ile de France",
  processes: [
    %Vae.Meta{
      title: "Faire une demande de financement de votre VAE à votre conseiller-e Pôle emploi",
      description: "Depuis pole-emploi.fr dans votre «espace personnel», dans la rubrique «mes échanges avec Pôle emploi» OU depuis l’application mobile dans la rubrique «contacter un conseiller»",
      attachment: %Vae.Attachment{
        type: "link",
        target: "https://candidat.pole-emploi.fr/candidat/espacepersonnel/authentification/"
      }
    }, %Vae.Meta{
      description: "Fournir votre accord de recevabilité + votre contrat d’accompagnement + votre devis d’accompagnement signé à votre conseiller-e qui se chargera d'envoyer la demande au Conseil Régional"
    }, %Vae.Meta{
      description: "Attendre l’accord de financement du Conseil Régional pour démarrer l’accompagnement, vous le recevrez chez vous"
    }
  ]
}

afpa_94_step3 = %Step{
  facultative: false,
  index: 3,
  title: "Demande de financement de l'accompagnement",
  description: "Pour obtenir le financement de votre VAE par Pôle emploi et le Conseil Régional d'Ile de France",
  processes: [
    %Vae.Meta{
      title: "Faire une demande de financement de votre VAE à votre conseiller-e Pôle emploi",
      description: "Depuis pole-emploi.fr dans votre «espace personnel», dans la rubrique «mes échanges avec Pôle emploi» OU depuis l’application mobile dans la rubrique «contacter un conseiller»",
      attachment: %Vae.Attachment{
        type: "link",
        target: "https://candidat.pole-emploi.fr/candidat/espacepersonnel/authentification/"
      }
    }, %Vae.Meta{
      description: "Fournir votre accord de recevabilité + votre contrat d’accompagnement + votre devis d’accompagnement signé à votre conseiller-e qui se chargera d'envoyer la demande au Conseil Régional"
    }, %Vae.Meta{
      description: "Attendre l’accord de financement du Conseil Régional pour démarrer l’accompagnement, vous le recevrez chez vous"
    }
  ]
}

afpa_95_step3 = %Step{
  facultative: false,
  index: 3,
  title: "Demande de financement de l'accompagnement",
  description: "Pour obtenir le financement de votre VAE par Pôle emploi et le Conseil Régional d'Ile de France",
  processes: [
    %Vae.Meta{
      title: "Faire une demande de financement de votre VAE à votre conseiller-e Pôle emploi",
      description: "Depuis pole-emploi.fr dans votre «espace personnel», dans la rubrique «mes échanges avec Pôle emploi» OU depuis l’application mobile dans la rubrique «contacter un conseiller»",
      attachment: %Vae.Attachment{
        type: "link",
        target: "https://candidat.pole-emploi.fr/candidat/espacepersonnel/authentification/"
      }
    }, %Vae.Meta{
      description: "Fournir votre accord de recevabilité + votre contrat d’accompagnement + votre devis d’accompagnement signé à votre conseiller-e qui se chargera d'envoyer la demande au Conseil Régional"
    }, %Vae.Meta{
      description: "Attendre l’accord de financement du Conseil Régional pour démarrer l’accompagnement, vous le recevrez chez vous"
    }
  ]
}

###

afpa_75_93_step4 = %Step{
  facultative: false,
  index: 4,
  title: "Accompagnement (facultatif mais recommandé)",
  description: "Pour être aidé-e dans la rédaction du dossier professionnel, visiter le plateau technique du centre d’examen et vous préparer à la mise en situation (s’il y a lieu)",
  processes: [
    %Vae.Meta{
      description: "Contacter votre centre AFPA pour l’informer de l’accord de financement et prendre votre 1er rdv d’accompagnement"
    }
  ]
}

afpa_92_step4 = %Step{
  facultative: false,
  index: 4,
  title: "Accompagnement (facultatif mais recommandé)",
  description: "Pour être aidé-e dans la rédaction du dossier professionnel, visiter le plateau technique du centre d’examen et vous préparer à la mise en situation (s’il y a lieu)",
  processes: [
    %Vae.Meta{
      description: "Contacter votre centre AFPA pour l’informer de l’accord de financement et prendre votre 1er rdv d’accompagnement"
}
  ]
}

afpa_77_step4 = %Step{
  facultative: false,
  index: 4,
  title: "Accompagnement (facultatif mais recommandé)",
  description: "Pour être aidé-e dans la rédaction du dossier professionnel, visiter le plateau technique du centre d’examen et vous préparer à la mise en situation (s’il y a lieu)",
  processes: [
    %Vae.Meta{
      description: "Contacter votre centre AFPA pour l’informer de l’accord de financement et prendre votre 1er rdv d’accompagnement"
    }
  ]
}

afpa_78_step4 = %Step{
  facultative: false,
  index: 4,
  title: "Accompagnement (facultatif mais recommandé)",
  description: "Pour être aidé-e dans la rédaction du dossier professionnel, visiter le plateau technique du centre d’examen et vous préparer à la mise en situation (s’il y a lieu)",
  processes: [
    %Vae.Meta{
      description: "Contacter votre centre AFPA pour l’informer de l’accord de financement et prendre votre 1er rdv d’accompagnement"
    }
  ]
}

afpa_91_step4 = %Step{
  facultative: false,
  index: 4,
  title: "Accompagnement (facultatif mais recommandé)",
  description: "Pour être aidé-e dans la rédaction du dossier professionnel, visiter le plateau technique du centre d’examen et vous préparer à la mise en situation (s’il y a lieu)",
  processes: [
    %Vae.Meta{
      description: "Contacter votre centre AFPA pour l’informer de l’accord de financement et prendre votre 1er rdv d’accompagnement"
    }
  ]
}

afpa_94_step4 = %Step{
  facultative: false,
  index: 4,
  title: "Accompagnement (facultatif mais recommandé)",
  description: "Pour être aidé-e dans la rédaction du dossier professionnel, visiter le plateau technique du centre d’examen et vous préparer à la mise en situation (s’il y a lieu)",
  processes: [
    %Vae.Meta{
      description: "Contacter votre centre AFPA pour l’informer de l’accord de financement et prendre votre 1er rdv d’accompagnement"
    }
  ]
}

afpa_95_step4 = %Step{
  facultative: false,
  index: 4,
  title: "Accompagnement (facultatif mais recommandé)",
  description: "Pour être aidé-e dans la rédaction du dossier professionnel, visiter le plateau technique du centre d’examen et vous préparer à la mise en situation (s’il y a lieu)",
  processes: [
    %Vae.Meta{
      description: "Contacter votre centre AFPA pour l’informer de l’accord de financement et prendre votre 1er rdv d’accompagnement"
    }
  ]
}

###

afpa_75_93_step5 = %Step{
  facultative: false,
  index: 5,
  title: "Dossier professionnel (Livret 2)",
  description: "Pour présenter vos expériences, vos compétences, votre environnement de travail et vos outils, en lien avec le référentiel du titre professionnel visé",
  processes: [
    %Vae.Meta{
      description: "Elaborer le dossier professionnel (livret 2)",
      attachment: %Vae.Attachment{
        type: "document",
        target: "https://www.google.fr/url?sa=t&rct=j&q=&esrc=s&source=web&cd=2&cad=rja&uact=8&ved=0ahUKEwiwu_OPuYHVAhWE1xoKHSFFAVwQFggtMAE&url=https%3A%2F%2Fdfpc.gouv.nc%2Fsites%2Fdefault%2Ffiles%2Ftelechargement%2Fdossier_professionnel_vf.docx&usg=AFQjCNFosbFmj_JabXWsVyjnZU2CMwiwEQ"
      }
    }, %Vae.Meta{
      description: "Remettre votre dossier professionnel à l’AFPA lorsqu’il est finalisé"
    }
  ]
}

afpa_92_step5 = %Step{
  facultative: false,
  index: 5,
  title: "Dossier professionnel (Livret 2)",
  description: "Pour présenter vos expériences, vos compétences, votre environnement de travail et vos outils, en lien avec le référentiel du titre professionnel visé",
  processes: [
    %Vae.Meta{
      description: "Elaborer le dossier professionnel (livret 2)",
      attachment: %Vae.Attachment{
        type: "document",
        target: "https://www.google.fr/url?sa=t&rct=j&q=&esrc=s&source=web&cd=2&cad=rja&uact=8&ved=0ahUKEwiwu_OPuYHVAhWE1xoKHSFFAVwQFggtMAE&url=https%3A%2F%2Fdfpc.gouv.nc%2Fsites%2Fdefault%2Ffiles%2Ftelechargement%2Fdossier_professionnel_vf.docx&usg=AFQjCNFosbFmj_JabXWsVyjnZU2CMwiwEQ"
      }
}, %Vae.Meta{
      description: "Remettre votre dossier professionnel à l’AFPA lorsqu’il est finalisé"
}
  ]
}

afpa_77_step5 = %Step{
  facultative: false,
  index: 5,
  title: "Dossier professionnel (Livret 2)",
  description: "Pour présenter vos expériences, vos compétences, votre environnement de travail et vos outils, en lien avec le référentiel du titre professionnel visé",
  processes: [
    %Vae.Meta{
      description: "Elaborer le dossier professionnel (livret 2)",
      attachment: %Vae.Attachment{
        type: "document",
        target: "https://www.google.fr/url?sa=t&rct=j&q=&esrc=s&source=web&cd=2&cad=rja&uact=8&ved=0ahUKEwiwu_OPuYHVAhWE1xoKHSFFAVwQFggtMAE&url=https%3A%2F%2Fdfpc.gouv.nc%2Fsites%2Fdefault%2Ffiles%2Ftelechargement%2Fdossier_professionnel_vf.docx&usg=AFQjCNFosbFmj_JabXWsVyjnZU2CMwiwEQ"
      }
    }, %Vae.Meta{
      description: "Remettre votre dossier professionnel à l’AFPA lorsqu’il est finalisé"
    }
  ]
}

afpa_78_step5 = %Step{
  facultative: false,
  index: 5,
  title: "Dossier professionnel (Livret 2)",
  description: "Pour présenter vos expériences, vos compétences, votre environnement de travail et vos outils, en lien avec le référentiel du titre professionnel visé",
  processes: [
    %Vae.Meta{
      description: "Elaborer le dossier professionnel (livret 2)",
      attachment: %Vae.Attachment{
        type: "document",
        target: "https://www.google.fr/url?sa=t&rct=j&q=&esrc=s&source=web&cd=2&cad=rja&uact=8&ved=0ahUKEwiwu_OPuYHVAhWE1xoKHSFFAVwQFggtMAE&url=https%3A%2F%2Fdfpc.gouv.nc%2Fsites%2Fdefault%2Ffiles%2Ftelechargement%2Fdossier_professionnel_vf.docx&usg=AFQjCNFosbFmj_JabXWsVyjnZU2CMwiwEQ"
      }
    }, %Vae.Meta{
      description: "Remettre votre dossier professionnel à l’AFPA lorsqu’il est finalisé"
    }
  ]
}

afpa_91_step5 = %Step{
  facultative: false,
  index: 5,
  title: "Dossier professionnel (Livret 2)",
  description: "Pour présenter vos expériences, vos compétences, votre environnement de travail et vos outils, en lien avec le référentiel du titre professionnel visé",
  processes: [
    %Vae.Meta{
      description: "Elaborer le dossier professionnel (livret 2)",
      attachment: %Vae.Attachment{
        type: "document",
        target: "https://www.google.fr/url?sa=t&rct=j&q=&esrc=s&source=web&cd=2&cad=rja&uact=8&ved=0ahUKEwiwu_OPuYHVAhWE1xoKHSFFAVwQFggtMAE&url=https%3A%2F%2Fdfpc.gouv.nc%2Fsites%2Fdefault%2Ffiles%2Ftelechargement%2Fdossier_professionnel_vf.docx&usg=AFQjCNFosbFmj_JabXWsVyjnZU2CMwiwEQ"
      }
    }, %Vae.Meta{
      description: "Remettre votre dossier professionnel à l’AFPA lorsqu’il est finalisé"
    }
  ]
}

afpa_94_step5 = %Step{
  facultative: false,
  index: 5,
  title: "Dossier professionnel (Livret 2)",
  description: "Pour présenter vos expériences, vos compétences, votre environnement de travail et vos outils, en lien avec le référentiel du titre professionnel visé",
  processes: [
    %Vae.Meta{
      description: "Elaborer le dossier professionnel (livret 2)",
      attachment: %Vae.Attachment{
        type: "document",
        target: "https://www.google.fr/url?sa=t&rct=j&q=&esrc=s&source=web&cd=2&cad=rja&uact=8&ved=0ahUKEwiwu_OPuYHVAhWE1xoKHSFFAVwQFggtMAE&url=https%3A%2F%2Fdfpc.gouv.nc%2Fsites%2Fdefault%2Ffiles%2Ftelechargement%2Fdossier_professionnel_vf.docx&usg=AFQjCNFosbFmj_JabXWsVyjnZU2CMwiwEQ"
      }
    }, %Vae.Meta{
      description: "Remettre votre dossier professionnel à l’AFPA lorsqu’il est finalisé"
    }
  ]
}

afpa_95_step5 = %Step{
  facultative: false,
  index: 5,
  title: "Dossier professionnel (Livret 2)",
  description: "Pour présenter vos expériences, vos compétences, votre environnement de travail et vos outils, en lien avec le référentiel du titre professionnel visé",
  processes: [
    %Vae.Meta{
      description: "Elaborer le dossier professionnel (livret 2)",
      attachment: %Vae.Attachment{
        type: "document",
        target: "https://www.google.fr/url?sa=t&rct=j&q=&esrc=s&source=web&cd=2&cad=rja&uact=8&ved=0ahUKEwiwu_OPuYHVAhWE1xoKHSFFAVwQFggtMAE&url=https%3A%2F%2Fdfpc.gouv.nc%2Fsites%2Fdefault%2Ffiles%2Ftelechargement%2Fdossier_professionnel_vf.docx&usg=AFQjCNFosbFmj_JabXWsVyjnZU2CMwiwEQ"
      }
    }, %Vae.Meta{
      description: "Remettre votre dossier professionnel à l’AFPA lorsqu’il est finalisé"
    }
  ]
}

###

afpa_75_93_step6 = %Step{
  facultative: false,
  index: 6,
  title: "Passage devant le jury et mise en situation (pour la majorité des titres professionnels)",
  description: "Pour soutenir votre dossier professionnel  et faire évaluer vos compétences, devant un jury constitué de formateurs du titre professionnel",
  processes: [
    %Vae.Meta{
      description: "Préparation de cet oral avec votre conseiller en accompagnement VAE et par un entretien préalable avec un formateur et par la visite du plateau technique de mise en situation (compris dans l’accompagnement)"
    }, %Vae.Meta{
      description: "Convocation à une session de mise en situation  professionnelle"
    }, %Vae.Meta{
      title: "Mise en situation",
      description: "Vous serez invité-e à effectuer des tâches dans les mêmes conditions que le contexte professionnel du titre professionnel visé (La durée est variable selon le titre professionnel visé)"
    }, %Vae.Meta{
      description: "Entretien individuel avec le jury"
    }
  ]
}

afpa_92_step6 = %Step{
  facultative: false,
  index: 6,
  title: "Passage devant le jury et mise en situation (pour la majorité des titres professionnels)",
  description: "Pour soutenir votre dossier professionnel  et faire évaluer vos compétences, devant un jury constitué de formateurs du titre professionnel",
  processes: [
    %Vae.Meta{
      description: "Préparation de cet oral avec votre conseiller en accompagnement VAE et par un entretien préalable avec un formateur et par la visite du plateau technique de mise en situation (compris dans l’accompagnement)"
    }, %Vae.Meta{
      description: "Convocation à une session de mise en situation  professionnelle"
    }, %Vae.Meta{
      title: "Mise en situation",
      description: "Vous serez invité-e à effectuer des tâches dans les mêmes conditions que le contexte professionnel du titre professionnel visé (La durée est variable selon le titre professionnel visé)"
    }, %Vae.Meta{
      description: "Entretien individuel avec le jury"
    }
  ]
}

afpa_77_step6 = %Step{
  facultative: false,
  index: 6,
  title: "Passage devant le jury et mise en situation (pour la majorité des titres professionnels)",
  description: "Pour soutenir votre dossier professionnel  et faire évaluer vos compétences, devant un jury constitué de formateurs du titre professionnel",
  processes: [
    %Vae.Meta{
      description: "Préparation de cet oral avec votre conseiller en accompagnement VAE et par un entretien préalable avec un formateur et par la visite du plateau technique de mise en situation (compris dans l’accompagnement)"
    }, %Vae.Meta{
      description: "Convocation à une session de mise en situation  professionnelle"
    }, %Vae.Meta{
      title: "Mise en situation",
      description: "Vous serez invité-e à effectuer des tâches dans les mêmes conditions que le contexte professionnel du titre professionnel visé (La durée est variable selon le titre professionnel visé)"
    }, %Vae.Meta{
      description: "Entretien individuel avec le jury"
    }
  ]
}

afpa_78_step6 = %Step{
  facultative: false,
  index: 6,
  title: "Passage devant le jury et mise en situation (pour la majorité des titres professionnels)",
  description: "Pour soutenir votre dossier professionnel  et faire évaluer vos compétences, devant un jury constitué de formateurs du titre professionnel",
  processes: [
    %Vae.Meta{
      description: "Préparation de cet oral avec votre conseiller en accompagnement VAE et par un entretien préalable avec un formateur et par la visite du plateau technique de mise en situation (compris dans l’accompagnement)"
    }, %Vae.Meta{
      description: "Convocation à une session de mise en situation  professionnelle"
    }, %Vae.Meta{
      title: "Mise en situation",
      description: "Vous serez invité-e à effectuer des tâches dans les mêmes conditions que le contexte professionnel du titre professionnel visé (La durée est variable selon le titre professionnel visé)"
    }, %Vae.Meta{
      description: "Entretien individuel avec le jury"
    }
  ]
}

afpa_91_step6 = %Step{
  facultative: false,
  index: 6,
  title: "Passage devant le jury et mise en situation (pour la majorité des titres professionnels)",
  description: "Pour soutenir votre dossier professionnel  et faire évaluer vos compétences, devant un jury constitué de formateurs du titre professionnel",
  processes: [
    %Vae.Meta{
      description: "Préparation de cet oral avec votre conseiller en accompagnement VAE et par un entretien préalable avec un formateur et par la visite du plateau technique de mise en situation (compris dans l’accompagnement)"
    }, %Vae.Meta{
      description: "Convocation à une session de mise en situation  professionnelle"
    }, %Vae.Meta{
      title: "Mise en situation",
      description: "Vous serez invité-e à effectuer des tâches dans les mêmes conditions que le contexte professionnel du titre professionnel visé (La durée est variable selon le titre professionnel visé)"
    }, %Vae.Meta{
      description: "Entretien individuel avec le jury"
    }
  ]
}

afpa_94_step6 = %Step{
  facultative: false,
  index: 6,
  title: "Passage devant le jury et mise en situation (pour la majorité des titres professionnels)",
  description: "Pour soutenir votre dossier professionnel  et faire évaluer vos compétences, devant un jury constitué de formateurs du titre professionnel",
  processes: [
    %Vae.Meta{
      description: "Préparation de cet oral avec votre conseiller en accompagnement VAE et par un entretien préalable avec un formateur et par la visite du plateau technique de mise en situation (compris dans l’accompagnement)"
    }, %Vae.Meta{
      description: "Convocation à une session de mise en situation  professionnelle"
    }, %Vae.Meta{
      title: "Mise en situation",
      description: "Vous serez invité-e à effectuer des tâches dans les mêmes conditions que le contexte professionnel du titre professionnel visé (La durée est variable selon le titre professionnel visé)"
    }, %Vae.Meta{
      description: "Entretien individuel avec le jury"
    }
  ]
}

afpa_95_step6 = %Step{
  facultative: false,
  index: 6,
  title: "Passage devant le jury et mise en situation (pour la majorité des titres professionnels)",
  description: "Pour soutenir votre dossier professionnel  et faire évaluer vos compétences, devant un jury constitué de formateurs du titre professionnel",
  processes: [
    %Vae.Meta{
      description: "Préparation de cet oral avec votre conseiller en accompagnement VAE et par un entretien préalable avec un formateur et par la visite du plateau technique de mise en situation (compris dans l’accompagnement)"
    }, %Vae.Meta{
      description: "Convocation à une session de mise en situation  professionnelle"
    }, %Vae.Meta{
      title: "Mise en situation",
      description: "Vous serez invité-e à effectuer des tâches dans les mêmes conditions que le contexte professionnel du titre professionnel visé (La durée est variable selon le titre professionnel visé)"
    }, %Vae.Meta{
      description: "Entretien individuel avec le jury"
    }
  ]
}

###

afpa_75_93_step7 = %Step{
  facultative: false,
  index: 7,
  title: "Résultat",
  description: "Les résultats vous seront communiqués quelques semaines après l’oral, par courrier, par la DIRECCTE. 3 situations possibles :",
  processes: [
    %Vae.Meta{
      description: "La réussite : Bravo !"
    }, %Vae.Meta{
      description: "La réussite partielle : Bravo, une partie de vos compétences est attestée et vous pouvez les compléter !"
    }, %Vae.Meta{
      description: "La non-obtention : Rapprochez-vous de votre conseiller pour convenir de propositions adaptées"
    }
  ]
}

afpa_92_step7 = %Step{
  facultative: false,
  index: 7,
  title: "Résultat",
  description: "Les résultats vous seront communiqués quelques semaines après l’oral, par courrier, par la DIRECCTE. 3 situations possibles :",
  processes: [
    %Vae.Meta{
      description: "La réussite : Bravo !"
}, %Vae.Meta{
      description: "La réussite partielle : Bravo, une partie de vos compétences est attestée et vous pouvez les compléter !"
}, %Vae.Meta{
      description: "La non-obtention : Rapprochez-vous de votre conseiller pour convenir de propositions adaptées"
}
  ]
}

afpa_77_step7 = %Step{
  facultative: false,
  index: 7,
  title: "Résultat",
  description: "Les résultats vous seront communiqués quelques semaines après l’oral, par courrier, par la DIRECCTE. 3 situations possibles :",
  processes: [
    %Vae.Meta{
      description: "La réussite : Bravo !"
    }, %Vae.Meta{
      description: "La réussite partielle : Bravo, une partie de vos compétences est attestée et vous pouvez les compléter !"
    }, %Vae.Meta{
      description: "La non-obtention : Rapprochez-vous de votre conseiller pour convenir de propositions adaptées"
    }
  ]
}

afpa_78_step7 = %Step{
  facultative: false,
  index: 7,
  title: "Résultat",
  description: "Les résultats vous seront communiqués quelques semaines après l’oral, par courrier, par la DIRECCTE. 3 situations possibles :",
  processes: [
    %Vae.Meta{
      description: "La réussite : Bravo !"
    }, %Vae.Meta{
      description: "La réussite partielle : Bravo, une partie de vos compétences est attestée et vous pouvez les compléter !"
    }, %Vae.Meta{
      description: "La non-obtention : Rapprochez-vous de votre conseiller pour convenir de propositions adaptées"
    }
  ]
}

afpa_91_step7 = %Step{
  facultative: false,
  index: 7,
  title: "Résultat",
  description: "Les résultats vous seront communiqués quelques semaines après l’oral, par courrier, par la DIRECCTE. 3 situations possibles :",
  processes: [
    %Vae.Meta{
      description: "La réussite : Bravo !"
    }, %Vae.Meta{
      description: "La réussite partielle : Bravo, une partie de vos compétences est attestée et vous pouvez les compléter !"
    }, %Vae.Meta{
      description: "La non-obtention : Rapprochez-vous de votre conseiller pour convenir de propositions adaptées"
    }
  ]
}

afpa_94_step7 = %Step{
  facultative: false,
  index: 7,
  title: "Résultat",
  description: "Les résultats vous seront communiqués quelques semaines après l’oral, par courrier, par la DIRECCTE. 3 situations possibles :",
  processes: [
    %Vae.Meta{
      description: "La réussite : Bravo !"
    }, %Vae.Meta{
      description: "La réussite partielle : Bravo, une partie de vos compétences est attestée et vous pouvez les compléter !"
    }, %Vae.Meta{
      description: "La non-obtention : Rapprochez-vous de votre conseiller pour convenir de propositions adaptées"
    }
  ]
}

afpa_95_step7 = %Step{
  facultative: false,
  index: 7,
  title: "Résultat",
  description: "Les résultats vous seront communiqués quelques semaines après l’oral, par courrier, par la DIRECCTE. 3 situations possibles :",
  processes: [
    %Vae.Meta{
      description: "La réussite : Bravo !"
    }, %Vae.Meta{
      description: "La réussite partielle : Bravo, une partie de vos compétences est attestée et vous pouvez les compléter !"
    }, %Vae.Meta{
      description: "La non-obtention : Rapprochez-vous de votre conseiller pour convenir de propositions adaptées"
    }
  ]
}

drjscs_step1 = %Step{
  facultative: false,
  index: 1,
  title: "Demande de recevabilité (livret 1)",
  description: "Pour vérifier les conditions de recevabilité de votre demande",
  processes: [
    %Vae.Meta{
      description: "Remplir le livret 1 (partie 1)",
      attachment: %Vae.Attachment{
        type: "document",
        target: "http://ile-de-france.drjscs.gouv.fr/sites/ile-de-france.drjscs.gouv.fr/IMG/doc/LIVRET_VAE_PARTIE_1-2.doc"
      }
    }, %Vae.Meta{
      description: "Renvoyer par courrier le livret 1 et vos justificatifs en 2 exemplaires (dont un original) à la DRJSCS"
    }, %Vae.Meta{
      description: "Attendre l’avis de recevabilité pour solliciter un accompagnement de votre parcours VAE. Avec votre avis de recevabilité, vous recevrez votre date et votre lieu de jury"
    }
  ]
}

drjscs_step2 = %Step{
  facultative: false,
  index: 2,
  title: "Identifier votre organisme d’accompagnement référencé par la Région IDF (afin que le coût puisse être pris en charge)",
  description: "Pour solliciter un accompagnement de votre VAE",
  processes: [
    %Vae.Meta{
      title: "Si vous avez identifié un organisme accompagnateur VAE",
      description: "Faites-vous confirmer qu’il est bien référencé par la région IDF. L’organisme peut vous le confirmer sinon, vous pouvez faire cette demande à votre conseiller Pôle emploi depuis votre « espace personnel », dans la rubrique « mes échanges avec Pôle emploi » OU  depuis l’application mobile dans la rubrique « contacter un conseiller »
"
}, %Vae.Meta{
      title: "Si vous n’avez pas identifié d’organisme accompagnateur VAE",
      description: "Adressez une demande à votre conseiller Pôle emploi depuis votre « espace personnel », dans la rubrique « mes échanges avec Pôle emploi » OU  depuis l’application mobile dans la rubrique « contacter un conseiller ». Il pourra vous proposer les coordonnées d’un organisme accompagnateur référencé par la Région IDF pour la VAE de votre diplôme"
    }, %Vae.Meta{
      description: "Contacter l’organisme accompagnateur retenu et demandez-lui un devis et un contrat d’accompagnement nominatifs et personnalisés."
    }
  ]
}

drjscs_step3 = %Step{
  facultative: true,
  index: 3,
  title: "Demande de financement (chéquier unique)",
  description: "Pour financer l’accompagnement de votre VAE",
  processes: [
    %Vae.Meta{
      title: "Faire une demande de financement de votre VAE à votre conseiller-e Pôle emploi",
      description: "Depuis pole-emploi.fr dans votre «espace personnel», dans la rubrique «mes échanges avec Pôle emploi» OU depuis l’application mobile dans la rubrique «contacter un conseiller»",
      attachment: %Vae.Attachment {
        type: "link",
        target: "https://candidat.pole-emploi.fr/candidat/espacepersonnel/authentification/"
      }
    }, %Vae.Meta{
      description: "Fournir votre avis de recevabilité + votre contrat d’accompagnement + votre devis d’accompagnement signé à votre conseiller",
    }, %Vae.Meta{
      description: "Envoi de la demande de financement par votre conseiller"
    }, %Vae.Meta{
      description: "Attendre l’accord de financement du Conseil Régional pour démarrer l’accompagnement. Vous le recevrez chez vous"
    }
  ]
}

drjscs_step4 = %Step{
  facultative: true,
  index: 4,
  title: "Début de l'accompagnement",
  description: "Pour être aidé-e dans la rédaction du livret 2 et vous préparer au jury",
  processes: [
    %Vae.Meta{
      description: "Contacter votre organisme accompagnateur pour l’informer de l’accord de financement et prendre votre 1er rdv d’accompagnement"
    }
  ]
}

drjscs_step5 = %Step{
  facultative: false,
  index: 5,
  title: "Dossier d’expériences (Livret 2)",
  description: "Pour présenter vos expériences, vos compétences, votre environnement de travail et vos outils, en lien avec le référentiel du diplôme visé",
  processes: [
    %Vae.Meta{
      description: "Renseigner les deux parties du livret 2 (partie 2) ",
      attachment: %Vae.Attachment{
        type: "document",
        target: "http://ile-de-france.drjscs.gouv.fr/sites/ile-de-france.drjscs.gouv.fr/IMG/doc/LIVRET_VAE_PARTIE_2-2.doc"
      }
    }
  ]
}

drjscs_step6 = %Step{
  facultative: false,
  index: 6,
  title: "S’inscrire au jury régional du diplôme visé au moins 2 mois avant la date",
  description: "Pour remplir aux obligations administratives préalables à la soutenance devant le jury",
  processes: [
    %Vae.Meta{
      title: "Renvoyer au service organisateur (mentionné dans votre avis de recevabilité) les deux parties de votre dossier VAE en 4 exemplaires (dont 1 original)"
    },
    %Vae.Meta{
      description: "+ L’original de l’avis de recevabilité"
    },
    %Vae.Meta{
      description: "+ 1 certificat médical"
    },
    %Vae.Meta{
      description: "Un courrier (facultatif) pour demander un entretien avec le jury si vous le souhaitez"
    }
  ]
}

drjscs_step7 = %Step{
  facultative: false,
  index: 7,
  title: "Passage devant le jury",
  description: "Pour soutenir votre livret 2 et le faire évaluer, devant un jury constitué d’enseignant du diplôme et de professionnels du métier",
  processes: [
    %Vae.Meta{
      description: "Préparer cet oral avec votre conseiller en accompagnement VAE"
    }
  ]
}

drjscs_step8 = %Step{
  facultative: false,
  index: 8,
  title: "Résulltat",
  description: "Les résultats vous seront communiqués, par courrier, quelques semaines après l’oral",
  processes: [
    %Vae.Meta{
      description: "La réussite : Bravo !"
    }, %Vae.Meta{
      description: "La réussite partielle : Bravo, une partie de vos compétences est attestée et vous pouvez les compléter !"
    }, %Vae.Meta{
      description: "Non obtention : rapprochez-vous de votre conseiller pour convenir de propositions adaptées et rebondir"
    }
  ]
}

#Certifiers
youth_ministry_map = %{name: "Ministère de la jeunesse, des sports et de la cohésion sociale"}
youth_ministry = %Certifier{}
|> Certifier.changeset(youth_ministry_map)
|> Repo.insert!(on_conflict: [set: [name: youth_ministry_map.name]], conflict_target: :name)
|> Repo.preload(:certifications)
|> Repo.preload(:delegates)

drjcs = %Delegate{
  name: "DRJSCS Ile de France",
  address: %Address{
    street: "6, rue Eugène Oudiné",
    postal_code: "75013",
    city: "Paris"
  },
  contact: %Contact{
    telephone: "0140775500"
  }
}

educ_nat_map = %{name: "Ministère de l'Education Nationale"}
educ_nat = %Certifier{}
|> Certifier.changeset(educ_nat_map)
|> Repo.insert!(on_conflict: [set: [name: educ_nat_map.name]], conflict_target: :name)
|> Repo.preload(:certifications)
|> Repo.preload(:delegates)

cava_94 = %Delegate{
  name: "CAVA de Créteil",
  address: %Address{
    street: "12, rue Georges Enesco",
    postal_code: "94025 Cedex",
    city: "Créteil"
  },
  contact: %Contact{
    telephone: "0157026750",
    fax: "0157026748"
  }
}

cava_93 = %Delegate{
  name: "CAVA de Saint Denis",
  address: %Address{
    street: "2 rue Diderot",
    postal_code: "93200",
    city: "Saint-Denis"
  },
  contact: %Contact{
    telephone: "0155840370",
    fax: "0155840369"
  }
}

cava_77_ne = %Delegate{
  name: "CAVA de Meaux (Nord-Est)",
  address: %Address{
    street: "12 Boulevard Jean Rose",
    postal_code: "77100",
    city: "Meaux"
  },
  contact: %Contact{
    telephone: "0160256665",
    fax: "0160256665"
  }
}

cava_77_no = %Delegate{
  name: "CAVA de Torcy (Nord-Ouest)",
  address: %Address{
    street: "1 passage du belvédère",
    postal_code: "77200",
    city: "Torcy"
  },
  contact: %Contact{
    telephone: "0160061753",
    fax: "0160067127"
  }
}

cava_77_south = %Delegate{
  name: "CAVA de Melun (Sud)",
  address: %Address{
    street: "3 rue Galliéni",
    postal_code: "77000",
    city: "Melun"
  },
  contact: %Contact{
    telephone: "0164878470",
    fax: "0164378058"
  }
}

cava_77_east = %Delegate{
  name: "CAVA de Coulommiers (Est)",
  address: %Address{
    street: "6 rue des templiers",
    postal_code: "77120",
    city: "Coulommiers"
  },
  contact: %Contact{
    telephone: "0164753006",
    fax: "0164753022"
  }
}

dava75 = %Delegate{
  name: "DAVA",
  #additional: [
  #  {
  #    name: "RECTORAT DE PARIS – LE VISALTO"
  #  }, {
  #    name: "GIP-FCIP de Paris"
  #  }
  #],
  address: %Address{
    street: "12 Bd d’Indochine",
    postal_code: "75933",
    city: "Paris Cedex 19"
  },
  contact: %Contact{
    telephone: "0144623974",
    fax: "0144623970",
    emails: ["ce.dava@ac-paris.fr"]
  }
}

dava78 = %Delegate{
  name: "DAVA",
  #additional: [
  #  {
  #    name: "RECTORAT DE PARIS – LE VISALTO"
  #  }, {
  #    name: "GIP-FCIP de Paris"
  #  }
  #],
  address: %Address{
    street: "19, avenue du Centre - BP 70101",
    postal_code: "78053",
    city: "Saint-Quentin-en-Yvelines Cedex"
  },
  contact: %Contact{
    telephone: "0130835220",
    fax: "0130835216",
    emails: ["dava@ac-versailles.fr"]
  }
}

dava91 = %Delegate{
  name: "DAVA - Lycée Jean-Baptiste Corot",
  #additional: [
  #  {
  #    name: "RECTORAT DE PARIS – LE VISALTO"
  #  }, {
  #    name: "GIP-FCIP de Paris"
  #  }
  #],
  address: %Address{
    street: "9 place Davout",
    postal_code: "91600",
    city: "Savigny sur Orge"
  },
  contact: %Contact{
    telephone: "0130835217",
    fax: "0130835216",
    emails: ["dava@ac-versailles.fr"]
  }
}

dava92_north = %Delegate{
  name: "DAVA Nord",
  #additional: [
  #  {
  #    name: "RECTORAT DE PARIS – LE VISALTO"
  #  }, {
  #    name: "GIP-FCIP de Paris"
  #  }
  #],
  address: %Address{
    street: "2 à 6 bis avenue Vladimir Illitch Lenine",
    postal_code: "92000",
    city: "NANTERRE cedex"
  },
  contact: %Contact{
    telephone: "0147297973",
    fax: "0147253501",
    emails: ["dava.nanterre.92@ac-versailles.fr"]
  }
}

dava92_south = %Delegate{
  name: "DAVA Sud - Lycée Jean Monnet",
  #additional: [
  #  {
  #    name: "RECTORAT DE PARIS – LE VISALTO"
  #  }, {
  #    name: "GIP-FCIP de Paris"
  #  }
  #],
  address: %Address{
    street: "128 rue jean Jaurès",
    postal_code: "92120",
    city: "MONTROUGE"
  },
  contact: %Contact{
    telephone: "0141174414",
    fax: "0130835216",
    emails: ["dava@ac-versailles.fr"]
  }
}

health_ministry_map = %{name: "Ministère des affaires sociales et de la santé"}
health_ministry = %Certifier{}
|> Certifier.changeset(health_ministry_map)
|> Repo.insert!(on_conflict: [set: [name: health_ministry_map.name]], conflict_target: :name)
|> Repo.preload(:certifications)
|> Repo.preload(:delegates)

asp = %Delegate{
  name: "ASP - UNACESS",
  website: "http://vae.asp-public.fr/",
  #additional: [
  #  {
  #    name: "RECTORAT DE PARIS – LE VISALTO"
  #  }, {
  #    name: "GIP-FCIP de Paris"
  #  }
  #],
  address: %Address{
    street: "15, rue Léon Walras",
    postal_code: "87017",
    city: "LIMOGES Cedex1"
  },
  contact: %Contact{
    telephone: "0810017710"
  }
}

insert_delegate = fn struct, certifier  ->
  with {:ok, delegate} <- Repo.insert(struct) do
    delegate
    |> Repo.preload(:certifier)
    |> Ecto.Changeset.change
    |> Ecto.Changeset.put_assoc(:certifier, certifier)
    |> Repo.update
  else
    {:error, error} -> raise "Error while inserting delegates: #{error}"
  end
end

insert_delegates = fn (delegates, steps, ministry) ->
  Enum.map(delegates,
    fn struct ->
      with {:ok, delegate} <- insert_delegate.(struct, ministry) do
        delegate
        |> Repo.preload(:steps)
        |> Ecto.Changeset.change
        |> Ecto.Changeset.put_assoc(:steps, steps)
        |> Repo.update!
      else
        {:error, error} -> raise "Error while inserting steps: #{error}"
      end
    end)
end

drjcs_steps = [drjscs_step1,
               drjscs_step2,
               drjscs_step3,
               drjscs_step4,
               drjscs_step5,
               drjscs_step6,
               drjscs_step7,
               drjscs_step8]

insert_delegates.([drjcs], drjcs_steps, youth_ministry)

cava_idf = [cava_94, cava_93, cava_77_east, cava_77_south, cava_77_no, cava_77_ne]
cava_idf_steps = [cava_idf_step1,
                  cava_idf_step2,
                  cava_idf_step3,
                  cava_idf_step4,
                  cava_idf_step5,
                  cava_idf_step6,
                  cava_idf_step7]

insert_delegates.(cava_idf, cava_idf_steps, educ_nat)

dava_78_steps = [dava_78_step1,
                 dava_78_step2,
                 dava_78_step3,
                 dava_78_step4,
                 dava_78_step5,
                 dava_78_step6,
                 dava_78_step7]

insert_delegates.([dava78,
                   dava91,
                   dava92_north,
                   dava92_south], dava_78_steps, educ_nat)

dava_75_steps = [dava_75_step1,
                 dava_75_step2,
                 dava_75_step3,
                 dava_75_step4,
                 dava_75_step5,
                 dava_75_step6,
                 dava_75_step7]

insert_delegates.([dava75], dava_75_steps, educ_nat)

asp_steps = [asp_step1,
             asp_step2,
             asp_step3,
             asp_step4,
             asp_step5,
             asp_step6,
             asp_step7,
             asp_step8]

insert_delegates.([asp], asp_steps, health_ministry)

employment_ministry_map = %{name: "Ministère du travail de l'emploi de la formation professionnelle et du dialogue social"}
employment_ministry = %Certifier{}
|> Certifier.changeset(employment_ministry_map)
|> Repo.insert!(on_conflict: [set: [name: employment_ministry_map.name]], conflict_target: :name)
|> Repo.preload(:certifications)
|> Repo.preload(:delegates)

afpa_75_93 = %Delegate{
  name: "AFPA - Paris / Seine-Saint-Denis",
  website: "https://www.afpa.fr/",
  #additional: [
  #  {
  #    name: "RECTORAT DE PARIS – LE VISALTO"
  #  }, {
  #    name: "GIP-FCIP de Paris"
  #  }
  #],
  address: %Address{
    street: "8, rue Georges et Maï Politzer",
    postal_code: "75012",
    city: "Paris"
  },
  contact: %Contact{
    telephone: "0633703701",
    name: "Cécile Laumonier",
    emails: ["cecile.laumonier@afpa.fr"]
  }
}

afpa_75_93_steps = [afpa_75_93_step1,
                    afpa_75_93_step2,
                    afpa_75_93_step3,
                    afpa_75_93_step4,
                    afpa_75_93_step5,
                    afpa_75_93_step6,
                    afpa_75_93_step7
                   ]

insert_delegates.([afpa_75_93], afpa_75_93_steps, employment_ministry)

afpa_77_1 = %Delegate{
  name: "AFPA - Champs sur Marne",
  website: "https://www.afpa.fr/",
  #additional: [
  #  {
  #    name: "RECTORAT DE PARIS – LE VISALTO"
  #  }, {
  #    name: "GIP-FCIP de Paris"
  #  }
  #],
  address: %Address{
    street: "67-69, av. du Général de Gaulle",
    postal_code: "77420",
    city: "Champs-sur-Marne"
  },
  contact: %Contact{
    telephone: "0164688048",
    name: "Véronique Harrouin",
    emails: ["veronique.harrouin@afpa.fr"]
  }
}

afpa_77_2 = %Delegate{
  name: "AFPA - Melun",
  website: "https://www.afpa.fr/",
  #additional: [
  #  {
  #    name: "Unité Territoriale du 77 de la DIRECCTE IDF"
  #  }, {
  #    name: "Cité administrative - Bât C - 5ème étage"
  #  }
  #],
  address: %Address{
    street: "20 Quai Hippolyte Rossignol",
    postal_code: "77011",
    city: "Melun"
  },
  contact: %Contact{
    telephone: "0164688048",
    name: "Véronique Harrouin",
    emails: ["veronique.harrouin@afpa.fr"]
  }
}

afpa_77_3 = %Delegate{
  name: "AFPA - Meaux",
  website: "https://www.afpa.fr/",
  #additional: [
  #  {
  #    name: "Maison de l’Emploi et de la Formation Nord-Est 77 "
  #  }
  #],
  address: %Address{
    street: "12 boulevard Jean Rose – BP 103",
    postal_code: "77105",
    city: "Meaux cedex"
  },
  contact: %Contact{
    telephone: "0164688048",
    name: "Véronique Harrouin",
    emails: ["veronique.harrouin@afpa.fr"]
  }
}

afpa_77_steps = [afpa_77_step1,
                 afpa_77_step2,
                 afpa_77_step3,
                 afpa_77_step4,
                 afpa_77_step5,
                 afpa_77_step6,
                 afpa_77_step7
                ]

insert_delegates.([afpa_77_1,
                   afpa_77_2,
                   afpa_77_3], afpa_77_steps, employment_ministry)

afpa_78_1 = %Delegate{
  name: "AFPA - Elancourt",
  website: "https://www.afpa.fr/",
  #additional: [
  #  {
  #    name: "Maison sociale"
  #  }
  #],
  address: %Address{
    street: "Quartier des Sept Mares",
    postal_code: "78200",
    city: "Elancourt"
  },
  contact: %Contact{
    telephone: "0686836348",
    name: "Sophie Gazon",
    emails: ["sophie.gazon@afpa.fr"]
  }
}

afpa_78_2 = %Delegate{
  name: "AFPA - Mantes-Magnanville",
  website: "https://www.afpa.fr/",
  #additional: [
  #  {
  #    name: "Maison sociale"
  #  }
  #],
  address: %Address{
    street: "Rue des Graviers",
    postal_code: "78200",
    city: "Mantes-Magnanville"
  },
  contact: %Contact{
    telephone: "0686836348",
    name: "Sophie Gazon",
    emails: ["sophie.gazon@afpa.fr"]
  }
}

afpa_78_steps = [afpa_78_step1,
                 afpa_78_step2,
                 afpa_78_step3,
                 afpa_78_step4,
                 afpa_78_step5,
                 afpa_78_step6,
                 afpa_78_step7
                ]

insert_delegates.([afpa_78_1,
                   afpa_78_2], afpa_78_steps, employment_ministry)

afpa_91 = %Delegate{
  name: "AFPA - Evry / Ris-Orangis",
  website: "https://www.afpa.fr/",
  #additional: [
  #  {
  #    name: "Evry Ris-Orangis"
  #  }
  #],
  address: %Address{
    street: "2, av. Louis Aragon",
    postal_code: "91130",
    city: "Ris-Orangis"
  },
  contact: %Contact{
    telephone: "0169025829",
    name: "Laurence Taton",
    emails: ["laurence.taton@afpa.fr"]
  }
}

afpa_91_steps = [afpa_91_step1,
                 afpa_91_step2,
                 afpa_91_step3,
                 afpa_91_step4,
                 afpa_91_step5,
                 afpa_91_step6,
                 afpa_91_step7
                ]

insert_delegates.([afpa_91], afpa_91_steps, employment_ministry)


afpa_92_1 = %Delegate{
  name: "AFPA - Plessis-Robinson",
  website: "https://www.afpa.fr/",
  #additional: [
  #  {
  #    name: "Plessis- Robinson"
  #  }
  #],
  address: %Address{
    street: "4, rue de Sceaux",
    postal_code: "92350",
    city: "Plessis-Robinson"
  },
  contact: %Contact{
    telephone: "0633713525",
    name: "Myriam Claude",
    emails: ["myriam.claude@afpa.fr"]
  }
}

afpa_92_2 = %Delegate{
  name: "AFPA - Meudon",
  website: "https://www.afpa.fr/",
  #additional: [
  #  {
  #    name: "Meudon"
  #  }, {
  #    name: "Zone Industrielle Vélizy"
  #  }
  #],
  address: %Address{
    street: "12-14 rue du Maréchal Juin",
    postal_code: "92366",
    city: "Meudon"
  },
  contact: %Contact{
    telephone: "0633713525",
    name: "Myriam Claude",
    emails: ["myriam.claude@afpa.fr"]
  }
}

afpa_92_3 = %Delegate{
  name: "AFPA - Nanterre",
  website: "https://www.afpa.fr/",
  #additional: [
  #  {
  #    name: "Nanterre"
  #  }
  #],
  address: %Address{
    street: "231, av. Georges Clémenceau",
    postal_code: "92000",
    city: "Nanterre"
  },
  contact: %Contact{
    telephone: "0633713525",
    name: "Myriam Claude",
    emails: ["myriam.claude@afpa.fr"]
  }
}

afpa_92_4 = %Delegate{
  name: "AFPA - Maison de l'Emploi et de la formation",
  website: "https://www.afpa.fr/",
  #additional: [
  #  {
  #    name: "Maison de l’Emploi et de la Formation "
  #  }
  #],
  address: %Address{
    street: "2-6 bis, av. Lénine",
    postal_code: "92000",
    city: "Nanterre"
  },
  contact: %Contact{
    telephone: "0633713525",
    name: "Myriam Claude",
    emails: ["myriam.claude@afpa.fr"]
  }
}

afpa_92_steps = [afpa_92_step1,
                 afpa_92_step2,
                 afpa_92_step3,
                 afpa_92_step4,
                 afpa_92_step5,
                 afpa_92_step6,
                 afpa_92_step7
                ]

insert_delegates.([afpa_92_1,
                   afpa_92_2,
                   afpa_92_3,
                   afpa_92_4], afpa_92_steps, employment_ministry)

afpa_94 = %Delegate{
  name: "AFPA - Créteil",
  website: "https://www.afpa.fr/",
  #additional: [
  #  {
  #    name: "Créteil"
  #  }
  #],
  address: %Address{
    street: "Zone Industrielle Le Closeau - Rue Marc Seguin",
    postal_code: "94015",
    city: "Créteil"
  },
  contact: %Contact{
    telephone: "0145137073",
    name: "Catherine De-Gulielmi",
    emails: ["catherine.deguglielmi@afpa.fr"]
  }
}

afpa_94_steps = [afpa_94_step1,
                 afpa_94_step2,
                 afpa_94_step3,
                 afpa_94_step4,
                 afpa_94_step5,
                 afpa_94_step6,
                 afpa_94_step7]

insert_delegates.([afpa_94], afpa_94_steps, employment_ministry)

afpa_95_1 = %Delegate{
  name: "AFPA - Saint-Ouen l’Aumône",
  website: "https://www.afpa.fr/",
  #additional: [
  #  {
  #    name: "Créteil"
  #  }
  #],
  address: %Address{
    street: "ZI du Vert Galant - 2 rue de la Garenne",
    postal_code: "95310",
    city: "Saint-Ouen l’Aumône"
  },
  contact: %Contact{
    telephone: "0134483095",
    name: "Samia Mouhous",
    emails: ["samia.mouhous@afpa.fr"]
  }
}

afpa_95_2 = %Delegate{
  name: "AFPA - Argenteuil",
  website: "https://www.afpa.fr/",
  #additional: [
  #  {
  #    name: "Créteil"
  #  }
  #],
  address: %Address{
    street: "80 rue de Verdun ",
    postal_code: "95100",
    city: "Argenteuil"
  },
  contact: %Contact{
    telephone: "0134483095",
    name: "Samia Mouhous",
    emails: ["samia.mouhous@afpa.fr"]
  }
}

afpa_95_steps = [afpa_95_step1,
                 afpa_95_step2,
                 afpa_95_step3,
                 afpa_95_step4,
                 afpa_95_step5,
                 afpa_95_step6,
                 afpa_95_step7
                ]

insert_delegates.([afpa_95_1,
                   afpa_95_2], afpa_95_steps, employment_ministry)
