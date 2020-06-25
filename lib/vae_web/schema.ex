defmodule VaeWeb.Schema do
  use Absinthe.Schema

  import_types(Absinthe.Type.Custom)
  import_types(__MODULE__.AccountTypes)
  import_types(__MODULE__.ApplicationTypes)
  import_types(__MODULE__.AuthoritiesTypes)
  import_types(__MODULE__.CertificationTypes)
  #  import_types(__MODULE__.MeetingTypes)

  alias VaeWeb.Resolvers.Resume

  query do
    import_fields(:account_queries)
    import_fields(:application_queries)
    import_fields(:authorities_queries)
    #    import_fields(:meeting_queries)
  end

  mutation do
    import_fields(:account_mutations)
    import_fields(:application_mutations)

    @desc "Delete a resume by its id"
    field(:delete_resume, :resume) do
      arg(:id, non_null(:id))
      resolve(&Resume.delete_resume/3)
    end
  end
end
