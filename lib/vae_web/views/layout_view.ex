defmodule VaeWeb.LayoutView do
  use VaeWeb, :view

  def base_layout(conn, assigns, do: contents) do
    render("_base.html", conn: conn, assigns: assigns, contents: contents)
  end

  @title_suffix "Avril la VAE facile - un service Pôle emploi"
  @default_description "Avril est un service visant à simplifier la démarche d'obtention d'un VAE, un diplôme obtenu par Validation des Acquis d'Expériences."

  def meta_data(assigns) do
    static_meta = Map.take(assigns, [:title, :description])
    dynamic_meta = dynamic_meta(assigns)

    %{
      title: title_with_suffix(Map.get(static_meta, :title) || Map.get(dynamic_meta, :title)),
      description:
        Map.get(static_meta, :description) || Map.get(dynamic_meta, :description) ||
          @default_description
    }
  end

  defp title_with_suffix(nil), do: @title_suffix
  defp title_with_suffix(title), do: "#{title} | #{@title_suffix}"

  defp dynamic_meta(%{
         view_module: Vae.CertificationView,
         view_template: "show.html",
         certification: c,
         delegate: d
       }) do
    %{
      title: "Diplôme #{Vae.Certification.name(c)} en VAE à #{d.name}",
      description:
        "Découvrez toutes les étapes VAE pour le diplôme #{Vae.Certification.name(c)} en VAE à #{
          d.name
        } et démarrez un suivi personnalisé."
    }
  end

  defp dynamic_meta(%{
         view_module: Vae.CertificationView,
         view_template: "show.html",
         certification: c
       }) do
    %{
      title: "Diplôme #{Vae.Certification.name(c)} en VAE",
      description:
        "Découvrez toutes les étapes VAE pour le diplôme #{Vae.Certification.name(c)} en VAE et trouvez votre centre VAE."
    }
  end

  defp dynamic_meta(%{view_module: Vae.CertificationView} = assigns) do
    %{
      title: "Diplômes compatibles avec la VAE#{meta_certification(Map.get(assigns, :meta))}",
      description:
        "Découvrez l'ensemble des diplômes compatibles avec la VAE#{
          meta_certification(Map.get(assigns, :meta))
        } pour vous lancer sans hésiter."
    }
  end

  defp dynamic_meta(%{view_module: Vae.DelegateView} = assigns) do
    %{
      title: "Certificateurs VAE#{meta_delegate(Map.get(assigns, :meta))}",
      description:
        "Trouvez le certificateur qui pourra vous faire obtenir votre diplôme VAE#{
          meta_certification(Map.get(assigns, :meta))
        } selon votre situation géographique."
    }
  end

  defp dynamic_meta(%{view_module: Vae.ProfessionView}) do
    %{
      title: "Métiers compatibles avec la VAE",
      description:
        "Affichez la liste des métiers compatibles avec la Validation des Acquis d'Expériences (VAE) pour vous lancer sans tarder."
    }
  end

  defp dynamic_meta(_assigns) do
    %{}
  end
end
