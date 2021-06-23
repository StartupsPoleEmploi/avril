defmodule VaeWeb.Schema do
  use Absinthe.Schema

  import_types(Absinthe.Type.Custom)
  import_types(VaeWeb.Schema.Types.Account)
  import_types(VaeWeb.Schema.Types.Application)
  import_types(VaeWeb.Schema.Types.Authorities)
  import_types(VaeWeb.Schema.Types.Certification)
  import_types(VaeWeb.Schema.Types.Profession)
  import_types(VaeWeb.Schema.Types.Search)

  alias VaeWeb.Resolvers.Resume

  input_object :edit_resume_input do
    field(:name, non_null(:string))
    field(:category, non_null(:string))
  end

  query do
    import_fields(:account_queries)
    import_fields(:application_queries)
    import_fields(:authorities_queries)

    import_fields(:public_searches)
  end

  mutation do
    import_fields(:account_mutations)
    import_fields(:application_mutations)

    @desc "Edit a resume by its id"
    field(:edit_resume, :resume) do
      arg(:id, non_null(:id))
      arg(:params, non_null(:edit_resume_input))
      resolve(&Resume.edit_resume/3)
    end
    @desc "Delete a resume by its id"
    field(:delete_resume, :resume) do
      arg(:id, non_null(:id))
      resolve(&Resume.delete_resume/3)
    end
  end
end
