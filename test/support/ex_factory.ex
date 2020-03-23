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
      city: "West Los Angeles"
    }
  end

  def certification_factory() do
    %Vae.Certification{
      label: "Certification One",
      acronym: "CO",
      level: "1",
      description:
        "My name is Maximus Decimus Meridius, commander of the Armies of the North, General of the Felix Legions and loyal servant to the true emperor, Marcus Aurelius. Father to a murdered son, husband to a murdered wife. And I will have my vengeance, in this life or the next.",
      delegates: [build(:delegate)]
    }
  end

  def application_factory() do
    %Vae.UserApplication{
      delegate: build(:delegate)
    }
  end
end
