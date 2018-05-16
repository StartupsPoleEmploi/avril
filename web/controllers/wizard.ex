defmodule Vae.Wizard do
  @moduledoc """
  Handles wizard behaviors.
  Setup a default wizard and put it in the user session.
  """

  # TODO: define a Vae.WizardStep struct
  @default_wizard [
    %{name: "Renseignez votre métier", url: "/", step: 1, status: :completed},
    %{
      name: "Découvrez les diplômes correspondants",
      url: "/certifications",
      step: 2,
      status: :disabled
    },
    %{
      name: "Trouvez votre certificateur",
      url: "/delegates",
      step: 3,
      status: :disabled
    },
    %{name: "Découvrez votre parcours V.A.E", url: "/", step: 4, status: :disabled}
  ]

  import Plug.Conn

  def completed_trails(),
    do: Enum.map(@default_wizard, fn trail -> %{trail | status: :completed} end)

  def init(opts), do: opts

  @doc """
  Inits the wizard with @default_wizard values
  """
  def call(conn, _opts) do
    wizard_trails = get_session(conn, :wizard_trails)
    assign(conn, :wizard_trails, wizard_trails || @default_wizard)
  end

  @doc """
  Updates the wizard and assigns the new state to the user session.
  """
  def update_wizard_trails(conn, opts) do
    [step: step, url: url] = opts

    wizard_trails =
      Map.get(conn.assigns, :wizard_trails, @default_wizard)
      |> Enum.split(step)
      |> update_status
      |> update_url(step, url)
      |> add_query_params(conn, step)

    conn
    |> put_session(:wizard_trails, wizard_trails)
    |> assign(:wizard_trails, wizard_trails)
  end

  @doc """
  Flags to :active the last wizard step and disables the remaining.
  After splitting wizard by the provided step, the last step in the first array is the active step.
  The second array contains steps to disable.
  """
  defp update_status({[h | []], to_disable}) do
    [
      Map.put(h, :status, :active)
      | update_in(to_disable, [Access.all(), :status], fn _ -> :disabled end)
    ]
  end

  @doc """
  Completes steps before the active step.
  """
  defp update_status({[h | t], to_disable}) do
    [Map.put(h, :status, :completed) | update_status({t, to_disable})]
  end

  @doc """
  Sets a new url if provided on update
  """
  defp update_url(wizard_trails, step, new_url) do
    update_in(wizard_trails, [Access.at(step - 1), :url], fn _url -> new_url end)
  end

  @doc """
  Add query params to the url.
  """
  defp add_query_params(wizard_trails, conn, step) do
    case conn.query_string do
      "" ->
        wizard_trails

      query_string ->
        update_in(wizard_trails, [Access.at(step - 1), :url], fn url ->
          "#{url}?#{query_string}"
        end)
    end
  end
end
