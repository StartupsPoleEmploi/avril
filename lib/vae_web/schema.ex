defmodule VaeWeb.Schema do
  use Absinthe.Schema

  import_types(Absinthe.Type.Custom)
  import_types(__MODULE__.AccountTypes)
  import_types(__MODULE__.ApplicationTypes)
  import_types(__MODULE__.AuthoritiesTypes)
  import_types(__MODULE__.CertificationTypes)

  query do
    import_fields(:account_queries)
    import_fields(:application_queries)
    import_fields(:authorities_queries)
  end

  mutation do
    import_fields(:account_mutations)
    import_fields(:application_mutations)
  end
end
