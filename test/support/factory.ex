defmodule Vae.Factory do
  alias Vae.Repo

  def build(:delegate) do
    %Vae.Delegate{name: unique_name("delegate")}
  end

  def build(:certifier_with_delegates) do
    %Vae.Certifier{
      name: unique_name("certifier"),
      delegates: [
        build(:delegate),
        build(:delegate)
      ]
    }
  end

  def build(factory_name, attributes) do
    factory_name |> build() |> struct(attributes)
  end

  def insert!(factory_name, attributes \\ []) do
    build(factory_name, attributes)
    |> Repo.insert!()
  end

  defp unique_name(prefix) do
    prefix <> Integer.to_string(System.unique_integer())
  end
end
