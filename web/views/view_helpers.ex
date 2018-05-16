defmodule Vae.ViewHelpers do
  @moduledoc """
  Conveniences for some html tags and conditions
  """

  use Phoenix.HTML

  @doc """
  Generates a link tag with target: _blank option
  """
  def target_blank(label \\ "", target, class \\ "") do
    link(label, to: target, class: class, target: "_blank")
  end

  def shorten_string(label, length \\ 30) do
    "#{String.slice(label, 0, length)}..."
  end

  def level_info(level) do
    {:safe,
     """
      <span>#{level_info_by_level(level)}</span>
     """}
  end

  def level_info_by_level(5), do: 'Niveau CAP / BEP'

  def level_info_by_level(4), do: 'Niveau Bac / BP / BT'

  def level_info_by_level(3), do: 'Bac +2 / DUT / BTS'

  def level_info_by_level(_), do: 'Sans Diplôme'

  def profession_title(count) do
    {:safe,
     count
     |> format_profession_title}
  end

  defp format_profession_title(professions_count) when professions_count > 1,
    do: "<strong>#{professions_count}</strong> métiers trouvés"

  defp format_profession_title(professions_count) when professions_count == 0,
    do: "Aucun métier trouvé"

  defp format_profession_title(professions_count),
    do: "<strong>#{professions_count}</strong> métier trouvé"

  def delegate_title(delegates, certification) do
    {:safe,
     length(delegates)
     |> format_delegate_title
     |> add_delegate_suffix(certification)}
  end

  defp format_delegate_title(delegates_count) when delegates_count > 1,
    do: "<strong>#{delegates_count}</strong> centres de certification trouvés"

  defp format_delegate_title(delegates_count) when delegates_count == 0,
    do: "Aucun certificateur trouvé"

  defp format_delegate_title(delegates_count),
    do: "<strong>#{delegates_count}</strong> certificateur trouvé"

  def add_delegate_suffix(count, certification) do
    count <>
      " pour <strong>#{certification.acronym} #{String.downcase(certification.label)}<strong>"
  end

  def not_nil?(map, term), do: Map.get(map, term) != nil
end
