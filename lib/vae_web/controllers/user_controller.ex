defmodule VaeWeb.UserController do
  use VaeWeb, :controller

  alias Vae.User

  def eligibility(conn, _params) do
    current_user = Pow.Plug.current_user(conn)
    render(conn, "eligibility.html", Map.merge(%{
      title: "Testez votre éligibilité VAE",
      description: "Avril vous informe en trois clics sur votre éligibilité à la VAE, la Validation des Acquis de l'Expérience.",
      total_hours: 1607,
      return_button: true,
      current_user: current_user,
    }, (if current_user, do: %{
      is_eligible: User.is_eligible(current_user),
      worked_hours: User.worked_hours(current_user),
    }, else: %{})))
  end
end

