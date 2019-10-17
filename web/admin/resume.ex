defmodule Vae.ExAdmin.Resume do
  use ExAdmin.Register

  register_resource Vae.Resume do

    index do
      column(:id)
      column(:file, fn r -> Phoenix.HTML.Link.link(r.filename, to: r.url) end)
      column(:inserted_at)
      actions()
    end

    action_items except: [:new, :delete, :edit]

    action_item :show, fn id ->
      resume = Vae.Repo.get(Vae.Resume, id) |> Vae.Repo.preload(:application)
      href = Vae.Router.Helpers.application_resume_path(Vae.Endpoint, :delete, resume.application, resume)
      action_item_link "Delete Resume", href: href, "data-method": :delete
    end

    # query do
    #   %{
    #     show: [preload: [:application]]
    #   }
    # end
  end
end
