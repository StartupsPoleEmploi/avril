defmodule VaeWeb.ErrorView do
  use VaeWeb, :view

  def render("404.html", assigns) do
    render("error.html",
      conn: assigns.conn,
      code: 404,
      message: "Il semblerait que vous vous soyez perdus !"
    )
  end

  def render("500.html", assigns) do
    render("error.html",
      conn: assigns.conn,
      code: 500,
      message: "Une erreur s'est produite"
    )
  end
end
