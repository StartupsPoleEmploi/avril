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

    @desc "Returns a booklet by application id"
    field(:booklet, :booklet) do
      arg(:application_id, non_null(:id))
      resolve(&Resolvers.Application.get_booklet/3)
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
    field(:certifier, :certifier) do
      resolve(&Resolvers.Authorities.certifier_item/3)
    end
    field(:booklet_1, :booklet)
    field(:resumes, list_of(:resume))
  end

  object :booklet do
    field(:inserted_at, :naive_datetime)
    field(:updated_at, :naive_datetime)
    field(:completed_at, :naive_datetime)
    field(:certification_name, :string)
    field(:certifier_name, :string)
    # field(:civility, :identity)
    field(:experiences, list_of(:experience))
    field(:education, :education)
  end

  object :experience do
    field(:uuid, :string)
    field(:title, :string)
    field(:company_name, :string)
    field(:job_industry, :string)
    field(:full_address, :address)
    field(:employment_type, :integer)
    field(:skills, list_of(:skill))
    field(:periods, list_of(:period))
  end

  object :period do
    field(:start_date, :date)
    field(:end_date, :date)
    field(:total_hours, :integer)
    field(:week_hours_duration, :integer)
  end

  object :skill do
    field(:label, :string)
  end

  object :education do
    field(:grade, :integer)
    field(:degree, :integer)
    field(:diplomas, list_of(:diploma))
    field(:courses, list_of(:course))
  end

  object :diploma do
    field(:label, :string)
  end

  object :course do
    field(:label, :string)
  end

  object :resume do
    field(:id, :id)
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

    @desc "Delete an application"
    field(:delete_application, :application) do
      arg(:id, non_null(:id))
      resolve(&Resolvers.Application.delete_application/3)
    end

    @desc "Upload and attach a resume to an application"
    field(:upload_resume, :application) do
      arg(:resume, non_null(:upload))
      arg(:id, non_null(:id))
      resolve(&Resolvers.Application.upload_resume/2)
    end

    @desc "Set booklet to an application"
    field(:set_booklet, :booklet) do
      arg(:input, non_null(:booklet_input))
      resolve(&Resolvers.Application.set_booklet/3)
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

  input_object :booklet_input do
    field(:application_id, non_null(:id))
    field(:booklet, non_null(:booklet_item))
  end

  input_object :booklet_item do
    field(:completed_at, :naive_datetime)
    field(:education, :education_input)
    field(:experiences, list_of(:experience_input))
  end

  input_object :education_input do
    field(:grade, :integer)
    field(:degree, :integer)
    field(:diplomas, list_of(:diploma_input))
    field(:courses, list_of(:course_input))
  end

  input_object :diploma_input do
    field(:label, :string)
  end

  input_object :course_input do
    field(:label, :string)
  end

  input_object :experience_input do
    field(:uuid, :string)
    field(:title, :string)
    field(:company_name, :string)
    field(:job_industry, :string)
    field(:employment_type, :integer)
    field(:skills, list_of(:skill_input))
    field(:periods, list_of(:period_input))
    field(:full_address, :full_address_input)
  end

  input_object :skill_input do
    field(:label, :string)
  end

  input_object :period_input do
    field(:start_date, :date)
    field(:end_date, :date)
    field(:week_hours_duration, :integer)
    field(:total_hours, :integer)
  end

  input_object :full_address_input do
    field(:city, :string)
    field(:county, :string)
    field(:country, :string)
    field(:lat, :float)
    field(:lng, :float)
    field(:street, :string)
    field(:postal_code, :string)
  end
end
