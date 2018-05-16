defmodule Vae.PageView do
  use Vae.Web, :view

  def search_input(form) do
    awesomplete(form, :for, [class: "form-control form-control-lg"], %{url: "/professions?search[for]=", value: "label", minChars: 3 })
  end
end
