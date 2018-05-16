defmodule Vae.RepoTest do
  use Vae.ModelCase

  alias Vae.Repo.NewRelic, as: Repo

  test "format_delegate_for_index" do
    delegate_to_index = Repo.format_delegate_for_index(nil)
    assert delegate_to_index == nil
  end
end
