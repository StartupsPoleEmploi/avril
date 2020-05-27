defmodule Vae.ExAdmin.Resume do
  use ExAdmin.Register
  alias Vae.ExAdmin.Helpers

  register_resource Vae.Resume do

    index do
      column(:id)
      column(:file, fn r -> Phoenix.HTML.Link.link(r.filename, to: r.url) end)
      column(:inserted_at)
      actions()
    end

    action_items except: [:new, :delete]

    show resume do
      attributes_table do
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

    # action_item :show, fn id ->
    #   resume = Vae.Repo.get(Vae.Resume, id) |> Vae.Repo.preload(:application)
    #   href = VaeWeb.Router.Helpers.user_application_resume_path(VaeWeb.Endpoint, :delete, resume.application, resume)
    #   action_item_link "Delete Resume", href: href, "data-method": :delete
    # end

    filter([:id, :content_type, :filename, :url, :inserted_at, :updated_at])

    # query do
    #   %{
    #     all: [preload: [:application]]
    #   }
    # end
  end
end
