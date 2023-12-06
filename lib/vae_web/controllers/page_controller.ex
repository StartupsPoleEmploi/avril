defmodule VaeWeb.PageController do
  use VaeWeb, :controller
  import Ecto.Query
  alias VaeWeb.Mailer
  alias Vae.{Certification, ContactForm, Delegate, DelegateContactForm, Repo, FAQ}
  alias VaeWeb.ContactEmail

  def index(conn, _params) do
    render(conn, "index.html",
      title: "Comment faire une VAE ?",
      certification_examples: Certification.is_active() |> Certification.sort_by_popularity() |> limit(10) |> Repo.all() |> Enum.take_random(2),
      delegate_examples: Delegate.is_active() |> Delegate.sort_by_popularity() |> limit(10) |> Repo.all() |> Enum.take_random(2)
    )
  end

  def faq(conn, _params) do
    render(conn, "faq.html",
      title: "Foire aux questions",
      description: "Nous répondons aux questions que vous vous posez sur Avril.",
      questions: from(f in FAQ, order_by: [asc: :order]) |> Repo.all()
    )
  end

  def vae(conn, _params) do
    render(conn, "vae.html",
      title: "Qu'est-ce que la VAE ?",
      description:
        "Comprendre comment obtenir un diplôme en Validation des Acquis d'Expérience (VAE), son dossier de candidature et d'expérience et son oral.",
      is_landing: true
    )
  end

  def terms_of_use(conn, _params) do
    render(conn, "terms-of-use.html",
      title: "Conditions générales d’utilisation",
      description:
        "Comme toute plateforme web, Avril inclue aussi des conditions générale d'utilisation.",
      is_landing: true
    )
  end

  def privacy_policy(conn, _params) do
    render(conn, "privacy_policy.html",
      title: "Politique de confidentialité",
      description:
        "Découvrez la politique de confidentialité d'Avril.",
      is_landing: true
    )
  end

  def receipts(conn, _params) do
    render(conn, "receipts.html",
      title: "Les justificatifs de la VAE",
      description:
        "La liste des justificatifs à fournir peut varier grandement selon la situation du candidat : voici le détail.",
      is_landing: true
    )
  end

  def choose_certification(conn, _params) do
    render(conn, "choose-certification.html",
      title: "Comment bien choisir son diplôme ?",
      description:
        "Pas évident de savoir à quel diplôme prétendre lorsqu'on se lance dans une VAE. Heureusement Avril va vous aider dans chacune des étapes du processus, et le choix du diplôme en fait partie.",
      is_landing: true
    )
  end

  def accessibility_promess(conn, _params) do
    render(conn, "accessibility-promess.html",
      title: "Avril et l'accessibilité",
      description:
        "Avril, service de Pôle-emploi, s'engage pour être accessible à tous les publics.",
      is_landing: true
    )
  end

  def point_relais_conseil(conn, _params) do
    render(conn, "point-relais-conseil.html",
      title: "Les Points Relais Conseil VAE",
      description:
        "Pour vous aider dans vos démarches VAE, les Points Relais Conseil (PRC) vous proposent un entretien individuel pour discuter de votre projet.",
      is_landing: true
    )
  end

  def certificateur_vae_definition(conn, _params) do
    render(conn, "certificateur-vae-definition.html",
      title: "C'est quoi un certificateur VAE ?",
      description:
        "Tout comprendre sur le certificateur VAE, l'organisme qui vous délivrera votre diplôme. DAVA, CAVA, ASP n'auront plus de secret pour vous.",
      is_landing: true
    )
  end

  def pourquoi_une_certification(conn, _params) do
    render(conn, "pourquoi-une-certification.html",
      title: "Pourquoi un VAE ?",
      description:
        "Pas toujours évident de se lancer dans le processus de VAE. Explorez les bonnes raisons de se lancer dans l'obtention du diplôme.",
      is_landing: true
    )
  end

  def financement(conn, _params) do
    render(conn, "financement.html",
      title: "Comment financer ma VAE ?",
      description:
        "Il existe de nombreuses solutions de financement pour votre projet de VAE. Decouvrez comment cela fonctionne."
    )
  end

  def synthesis(conn, _params) do
    render(conn, "synthesis.html",
      title: "Synthèse VAE",
      description: "Les différentes étapes d'une VAE expliquées en détail.",
      is_landing: true
    )
  end

  def stats(conn, params) do
    render(conn, "stats.html",
      title: "Statistiques Avril",
      description: "Statistiques de démarrage de candidatures VAE sur Avril",
      start_date: Vae.String.blank_is_nil(params["start_date"]) || (Date.utc_today() |> Timex.shift(months: -6) |> Timex.beginning_of_week()),
      # start_date: Vae.String.blank_is_nil(params["start_date"]) || (Date.utc_today() |> Timex.shift(months: -6) |> Date.beginning_of_week()),
      end_date: Vae.String.blank_is_nil(params["end_date"]) || Date.utc_today()
    )
  end

  def delegate_contact(conn, _params) do
    render(conn, "delegate_contact.html",
      title: "Me répertorier en tant que certificateur sur Avril",
      description:
        "Ecrivez-nous pour être référencé sur Avril en tant que certificateur VAE.",
      contact_changeset: %DelegateContactForm{} |> Ecto.Changeset.change()
    )
  end

  def submit_delegate_contact(conn, %{
        "delegate_contact_form" => variables
      }) do
    with(
      %Ecto.Changeset{valid?: true, changes: changes} <- DelegateContactForm.changeset(%DelegateContactForm{}, variables),
      {:ok, _messages} <- Mailer.send([
        ContactEmail.delegate_submit(changes),
        ContactEmail.delegate_confirm(changes)
      ])
    ) do
      conn
      |> put_flash(:success, "Votre demande a bien été envoyée.")
      |> redirect(to: Routes.root_path(conn, :index))
    else
      %Ecto.Changeset{} = changeset ->
        conn
        |> put_flash(:danger, "Votre demande n'a pas pu être envoyée. Les erreurs sont décrites ci-dessous.")
        |> render("contact.html",
          title: "Contacter l'équipe Avril",
          contact_changeset: changeset
        )
      error ->
        conn
         |> put_flash(:danger, "Votre demande n'a pas pu être envoyée : #{inspect(error)}. Merci de réessayer plus tard.")
         |> redirect(to: Routes.root_path(conn, :index))
    end
  end


  def contact(conn, _params) do
    render(conn, "contact.html",
      title: "Contacter l'équipe Avril",
      description:
        "Nous sommes disponibles pour répondre à toutes les questions techniques concernant la plateforme Avril.",
      contact_changeset: %ContactForm{} |> Ecto.Changeset.change()
    )
  end

  def submit_contact(conn, %{
        "contact_form" => variables
      }) do
    if Timex.after?(Timex.today(), Application.get_env(:vae, :deadlines)[:avril_pre_close]) do
      conn
        |> put_flash(:warning, Application.get_env(:vae, :messages)[:support_closed])
        |> redirect(to: Routes.root_path(conn, :index))
    else
      with(
        %Ecto.Changeset{valid?: true, changes: changes} <- ContactForm.changeset(%ContactForm{}, variables),
        {:ok, _messages} <- Mailer.send([ContactEmail.submit(changes), ContactEmail.confirm(changes)])
      ) do
        conn
        |> put_flash(:success, "Votre message a bien été envoyé.")
        |> redirect(to: Routes.root_path(conn, :index))
      else
        %Ecto.Changeset{} = changeset ->
          conn
          |> put_flash(:danger, "Votre message n'a pas pu être envoyé. Les erreurs sont décrites ci-dessous.")
          |> render("contact.html",
            title: "Contacter l'équipe Avril",
            contact_changeset: changeset
          )
        error ->
          conn
           |> put_flash(:danger, "Votre message n'a pas pu être envoyé : #{inspect(error)}. Merci de réessayer plus tard.")
           |> redirect(to: Routes.root_path(conn, :index))
      end
    end
  end

  def close_status(conn, %{"id" => id}) do
    ids = ((get_session(conn, :app_status_closed) || "") |> String.split(",", trim: true)) ++ [id] |> Enum.join(",")
    conn
    |> put_session(:app_status_closed, ids)
    |> json(:ok)
  end
end
