defmodule Vae.PageController do
  use Vae.Web, :controller

  def index(conn, _params) do
    render(conn, "index.html",
      title: "Comment faire une VAE ?",
      no_container: true,
      body_class: 'home'
    )
  end

  def vae(conn, _params) do
    render(conn, "vae.html",
      title: "Qu'est-ce que la VAE ?",
      description: "Comprendre comment obtenir un diplôme en Validation des Acquis d'Expérience (VAE), son dossier de candidature et d'expérience et son oral.",
      is_landing: true
    )
  end

  def terms_of_use(conn, _params) do
    render(conn, "terms-of-use.html",
      title: "Conditions générales d’utilisation",
      description: "Comme toute plateforme web, Avril inclue aussi des conditions générale d'utilisation.",
      is_landing: true
    )
  end

  def receipts(conn, _params) do
    render(conn, "receipts.html",
      title: "Les justificatifs de la VAE",
      description: "La liste des justificatifs à fournir peut varier grandement selon la situation du candidat : voici le détail.",
      return_button: true
    )
  end

  def choose_certification(conn, _params) do
    render(conn, "choose-certification.html",
      title: "Comment bien choisir son diplôme ?",
      description: "Pas évident de savoir à quel diplôme prétendre lorsqu'on se lance dans une VAE. Heureusement Avril va vous aider dans chacune des étapes du processus, et le choix du diplôme en fait partie.",
      is_landing: true
    )
  end

  def accessibility_promess(conn, _params) do
    render(conn, "accessibility-promess.html",
      title: "Avril et l'accessibilité",
      description: "Avril, service de Pôle-emploi, s'engage pour être accessible à tous les publics.",
      is_landing: true
    )
  end

  def point_relais_conseil(conn, _params) do
    render(conn, "point-relais-conseil.html",
      title: "Les Points Relais Conseil VAE",
      description: "Pour vous aider dans vos démarches VAE, les Points Relais Conseil (PRC) vous proposent un entretien individuel pour discuter de votre projet.",
      is_landing: true
    )
  end

  def certificateur_vae_definition(conn, _params) do
    render(conn, "certificateur-vae-definition.html",
      title: "C'est quoi un certificateur VAE ?",
      description: "Tout comprendre sur le certificateur VAE, l'organisme qui vous délivrera votre diplôme. DAVA, CAVA, ASP n'auront plus de secret pour vous.",
      is_landing: true,
      no_wrapper: true
    )
  end

  def pourquoi_une_certification(conn, _params) do
    render(conn, "pourquoi-une-certification.html",
      title: "Pourquoi un VAE ?",
      description: "Pas toujours évident de se lancer dans le processus de VAE. Explorez les bonnes raisons de se lancer dans l'obtention du diplôme.",
      is_landing: true
    )
  end

  def financement(conn, _params) do
    render(conn, "financement.html",
      title: "Comment financer ma VAE ?",
      description: "Il existe de nombreuses solutions de financement pour votre projet de VAE. Decouvrez comment cela fonctionne.",
      body_class: "bg-white"
    )
  end

  def contact(conn, _params) do
    render(conn, "contact.html",
      title: "Contacter l'équipe Avril",
      description: "Nous sommes disponibles pour répondre à toutes les questions techniques concernant la plateforme Avril.",
      contact_changeset: Vae.ContactForm.changeset(%Vae.ContactForm{})
    )
  end

  def submit_contact(conn, %{
    "contact_form" => %{} = variables
  }) do

    with {:ok, _messages} <- Vae.Mailer.send([
      Vae.ContactEmail.submit(variables),
      Vae.ContactEmail.confirm(variables)
    ]) do
      json(conn, %{status: :ok, msg: "Votre message a bien été envoyé."})
    else
      error ->
        conn
        |> send_resp(500, Poison.encode!(%{status: :error, msg: "Votre message n'a pas pu être envoyé : \n\n #{inspect(error)} \n\n Merci de réessayer plus tard."}, pretty: true))
    end
  end

  def close_status(conn, _params) do
    message = conn |> Map.get(:app_status) |> Map.get(:message)
    conn
      |> put_session(:app_status_closed, Vae.String.encode(message))
      |> json(:ok)
  end

  def stats(conn, _params) do
    redirect(conn, external: "https://datastudio.google.com/u/0/reporting/1t7iUT7wGQn9U7ODZeDyXIvIRlK-BJAZs/page/1M")
  end
end
