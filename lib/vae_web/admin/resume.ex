defmodule Vae.ExAdmin.Resume do
  use ExAdmin.Register

  register_resource Vae.Resume do

    index do
      column(:id)
      column(:file, fn r -> Phoenix.HTML.Link.link(r.filename, to: r.url) end)
      column(:inserted_at)
      actions()
    end

    action_items except: [:new, :delete]

    show _resume do
      attributes_table() do
        row(:id)
        row(:file, fn r -> Phoenix.HTML.Link.link(r.filename, to: r.url, target: "_blank", download: r.filename) end)
        row(:content_type)
        row(:inserted_at)
        row(:updated_at)
        row(:application)
      end
    end

    form resume do
      inputs do
        input(resume, :filename)
        input(resume, :url)
        input(resume, :content_type)
        input(resume, :inserted_at)
        input(resume, :updated_at)
      end
    end

    member_action :"delete",
      &__MODULE__.delete_resume/2,
      label: "Delete Resume",
      icon: "minus-square"

    def delete_resume(conn, %{id: id}) do
      resume = Vae.Repo.get(Vae.Resume, id)

      case Vae.Resume.delete(resume) do
        {:ok, _} ->
          conn
          |> Phoenix.Controller.put_flash(:notice, "Résumé supprimé")
          |> Phoenix.Controller.redirect(to: ExAdmin.Utils.admin_resource_path(Resume))
        _ ->
          conn
          |> Phoenix.Controller.put_flash(:danger, "Le résumé n'a pas été supprimé.")
          |> Phoenix.Controller.redirect(to: ExAdmin.Utils.admin_resource_path(resume))
      end
    end

    filter([:id, :content_type, :filename, :url, :inserted_at, :updated_at])
  end
end
