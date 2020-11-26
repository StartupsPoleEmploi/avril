defmodule Vae.ExAdmin.FAQ do
  use ExAdmin.Register

  register_resource Vae.FAQ do

    index do
      column(:id)
      column(:question)
      column(:order)
      actions()
    end

    show _resume do
      attributes_table() do
        row(:question, fn %Vae.FAQ{question: question} -> Phoenix.HTML.raw(question) end)
        row(:answer)
        row(:order)
      end
    end

    form resume do
      inputs do
        input(resume, :question)
        input(resume, :answer, type: :text)
        input(resume, :order)
      end
    end

    filter([:id, :question, :answer])

    query do
      %{
        index: [default_sort: [asc: :order]]
      }
    end

  end
end
