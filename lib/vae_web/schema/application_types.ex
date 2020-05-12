defmodule VaeWeb.Schema.ApplicationTypes do
  use Absinthe.Schema.Notation

  alias VaeWeb.Resolvers

  import_types(Absinthe.Plug.Types)

  object :application_queries do
    @desc "List user applications"
    field(:applications, list_of(:application)) do
      resolve(&Resolvers.Application.application_items/3)
    end

    @desc "Returns an application by its id only if the current user is the owner"
    field(:application, :application) do
      arg(:id, non_null(:id))
      resolve(&Resolvers.Application.application/3)
    end
  end

  object :application do
    field(:id, :id)
    field(:booklet_hash, :string)
    field(:inserted_at, :naive_datetime)
    field(:submitted_at, :naive_datetime)

    field(:meeting, :meeting)

    field(:delegate, :delegate)
    field(:certification, :certification)
    field(:booklet_1, :booklet)
    field(:resumes, list_of(:resume))
  end

  object :booklet do
    field(:inserted_at, :naive_datetime)
    field(:completed_at, :naive_datetime)
  end

  object :resume do
    field(:content_type, :string)
    field(:filename, :string)
    field(:url, :string)
  end

  object :application_mutations do
    @desc "Attach a delegate to an application"
    field(:attach_delegate, :application) do
      arg(:input, non_null(:attach_delegate_input))
      resolve(&Resolvers.Application.attach_delegate/3)
    end

    @desc "Register a meeting to an application"
    field(:register_meeting, :application) do
      arg(:input, non_null(:register_meeting_input))
      resolve(&Resolvers.Application.register_meeting/3)
    end

    @desc "Submit an application to a delegate"
    field(:submit_application, :application) do
      arg(:id, non_null(:id))
      resolve(&Resolvers.Application.submit_application/3)
    end

    @desc "Upload and attach a resume to an application"
    field(:upload_resume, :string) do
      arg(:resume, non_null(:upload))
      arg(:id, non_null(:id))
      resolve(&Resolvers.Application.upload_resume/2)
    end
  end

  input_object :attach_delegate_input do
    field(:application_id, non_null(:id))
    field(:delegate_id, non_null(:id))
  end

  input_object :register_meeting_input do
    field(:application_id, non_null(:id))
    field(:meeting_id, non_null(:id))
  end
end
