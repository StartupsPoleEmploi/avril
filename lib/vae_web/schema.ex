defmodule VaeWeb.Schema do
  use Absinthe.Schema

  import_types(Absinthe.Type.Custom)
  import_types(__MODULE__.ApplicationTypes)
  import_types(__MODULE__.AuthoritiesTypes)
  import_types(__MODULE__.CertificationTypes)

  query do
    import_fields(:application_queries)
    import_fields(:authorities_queries)
  end
end
