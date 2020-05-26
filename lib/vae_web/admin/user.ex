defmodule Vae.ExAdmin.User do
  use ExAdmin.Register
  alias Vae.ExAdmin.Helpers

  register_resource Vae.User do
    index do
      selectable_column()
      column(:id)
      column(:first_name)
      column(:last_name)
      column(:email)
      column(:city_label)
      column(:is_admin)

      actions()
    end

    form user do
      inputs do
        input(user, :first_name)
        input(user, :last_name)
        input(user, :email)
        input(user, :email_confirmed_at)
        input(user, :is_admin)
        input(user, :postal_code)
        input(user, :address1)
        input(user, :address2)
        input(user, :address3)
        input(user, :address4)
        input(user, :insee_code)
        input(user, :country_code)
        input(user, :city_label)
        input(user, :country_label)
        input(user, :pe_id)
        input(user, :pe_connect_token)
      end
    end

    filter([
      :identity,
      :first_name,
      :last_name,
      :email,
      :postal_code,
      :address1,
      :address2,
      :address3,
      :address4,
      :city_label,
      :country_label,
      :pe_id
    ])

    csv do
      column(:id)
      column(:first_name)
      column(:last_name)
      column(:email)
      column(:email_confirmed_at)
      column(:is_admin)
      column(:gender)
      column(:phone_number)
      column(:postal_code)
      column(:address1)
      column(:address2)
      column(:address3)
      column(:address4)
      column(:insee_code)
      column(:country_code)
      column(:city_label)
      column(:country_label)
      column(:birthday)
      column(:birth_place)
      column(:pe_id)
    end

    update_changeset(:admin_changeset)

    show user do
      attributes_table do
        row(:gender)
        row(:first_name)
        row(:last_name)
        row(:email)
        row(:email_confirmed_at)
        row(:is_admin)
        row(:phone_number)
        row(:postal_code)
        row(:address1)
        row(:address2)
        row(:address3)
        row(:address4)
        row(:insee_code)
        row(:country_code)
        row(:city_label)
        row(:country_label)
        row(:birthday)
        row(:birth_place)
        row(:pe_id)
        row(:identity, fn a -> Helpers.print_in_json(a.identity) end)
      end

      panel "Skills" do
        table_for user.skills do
          column(:code)
          column(:label)
          column(:type)
          column(:level_code)
          column(:level_label)
        end
      end

      panel "Experiences" do
        table_for user.experiences do
          column(:company)
          column(:start_date)
          column(:end_date)
          column(:is_current_job)
          column(:is_abroad)
          column(:label)
          column(:duration)
        end
      end

      panel "Proven Experiences" do
        table_for user.proven_experiences do
          column(:start_date)
          column(:end_date)
          column(:label)
          column(:contract_type)
          column(:is_manager)
          column(:work_duration)
          column(:duration)
          column(:company_ape)
          column(:company_name)
          column(:company_category)
          column(:company_state_owned)
          column(:company_uid)
        end
      end

      panel "Applications" do
        table_for user.applications do
          column(:id, fn a -> Helpers.link_to_resource(a, namify: fn a -> a.id end) end)

          column(:application_certification, fn a -> Helpers.link_to_resource(a.certification) end)

          column(:application_delegate, fn a -> Helpers.link_to_resource(a.delegate) end)

          column(:application_certifiers, fn a ->
            Enum.map(a.certifiers, &Helpers.link_to_resource/1)
          end)

          column(:administrative, fn a -> a.delegate && a.delegate.administrative end)
          column(:submitted_at)
          column(:admissible_at)
          column(:inadmissible_at)
        end
      end
    end

    query do
      %{
        index: [default_sort: [desc: :inserted_at]],
        show: [preload: [applications: [:delegate, :user, :certification, :certifiers]]]
      }
    end
  end
end
