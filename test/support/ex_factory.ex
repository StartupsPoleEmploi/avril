defmodule Vae.ExFactory do
  use ExMachina.Ecto, repo: Vae.Repo

  def user_factory() do
    %Vae.User{
      first_name: "Jane",
      last_name: "Doe"
    }
  end

  def delegate_factory() do
    %Vae.Delegate{
      name: "Delegate 1",
      person_name: "Marc Aurele",
      address: "3001  Meadowbrook Mall Road, 90025, West Los Angeles",
      city: "West Los Angeles",
      certifiers: [build(:certifier)]
    }
  end

  def certification_factory() do
    %Vae.Certification{
      label: generate_certification_label(),
      acronym: generate_certification_acronym(),
      level: "1",
      description:
        "My name is Maximus Decimus Meridius, commander of the Armies of the North, General of the Felix Legions and loyal servant to the true emperor, Marcus Aurelius. Father to a murdered son, husband to a murdered wife. And I will have my vengeance, in this life or the next.",
      delegates: [build(:delegate)]
    }
  end

  def certifier_factory() do
    %Vae.Certifier{
      name: generate_certifier_name()
    }
  end

  def application_factory() do
    %Vae.UserApplication{
      delegate: build(:delegate),
      certification: build(:certification)
    }
  end

  defp generate_certifier_name(), do: generate_random_string(12)

  defp generate_certification_label(), do: generate_random_string(12)

  defp generate_certification_acronym(), do: generate_random_string(2)

  defp generate_random_string(length) do
    :crypto.strong_rand_bytes(length) |> Base.encode64() |> binary_part(0, length)
  end
end
