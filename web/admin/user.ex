defmodule Vae.ExAdmin.User do
  use ExAdmin.Register

  register_resource Vae.User do

    index do
      selectable_column()
      column(:id)
      column(:first_name)
      column(:last_name)
      column(:email)
      column(:city_label)
      column(:sign_in_count)
      column(:is_admin)

      actions()
    end

    form user do
      inputs do
        input(user, :name)
        input(user, :first_name)
        input(user, :last_name)
        input(user, :email)
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

    filter [:name, :email, :postal_code, :address1, :address2, :address3, :address4, :city_label, :country_label]

    show user do
      attributes_table only: [
        :name,
        :first_name,
        :last_name,
        :email,
        :is_admin,
        :postal_code,
        :address1,
        :address2,
        :address3,
        :address4,
        :insee_code,
        :country_code,
        :city_label,
        :country_label,
        :pe_id,
        :pe_connect_token
      ]

      panel "Skills" do
        table_for user.skills do
          column :code
          column :label
          column :type
          column :level_code
          column :level_label
        end
      end

      panel "Experiences" do
        table_for user.experiences do
          column :company
          column :start_date
          column :end_date
          column :is_current_job
          column :is_abroad
          column :label
          column :duration
        end
      end
      panel "Proven Experiences" do
        table_for user.proven_experiences do
          column :start_date
          column :end_date
          column :label
          column :contract_type
          column :is_manager
          column :work_duration
          column :duration
          column :company_ape
          column :company_name
          column :company_category
          column :company_state_owned
          column :company_uid
        end
      end
    end
    query do
      %{index: [default_sort: [asc: :inserted_at]]}
    end
  end
end