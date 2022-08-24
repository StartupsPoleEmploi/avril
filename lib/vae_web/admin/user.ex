defmodule Vae.ExAdmin.User do
  use ExAdmin.Register
  alias Vae.{ExAdmin.Helpers, User}
  alias VaeWeb.Router.Helpers, as: Routes

  register_resource User do
    index do
      selectable_column()
      column(:id)
      column(:first_name)
      column(:last_name)
      column(:email)
      column(:is_admin)
      column(:is_delegate)

      actions()
    end

    form user do
      inputs do
        input(user, :first_name)
        input(user, :last_name)
        input(user, :email)
        input(user, :is_admin)
        input(user, :is_delegate)
        input(user, :pe_id)
      end
    end

    filter(:applications)
    filter([
      :first_name,
      :last_name,
      :email,
      :pe_id
    ])

    csv do
      column(:id)
      column(:first_name)
      column(:last_name)
      column(:email)
      column(:is_admin)
      column(:is_delegate)
      column(:pe_id)
      column(:identity)
    end

    show user do
      attributes_table() do
        row(:first_name)
        row(:last_name)
        row(:email)
        row(:is_admin)
        row(:is_delegate)
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

          column(:administrative, fn a -> a.delegate && a.delegate.administrative end)
          column(:submitted_at)
          column(:admissible_at)
          column(:inadmissible_at)
          column(:raised_at)
        end
      end
    end

    query do
      %{
        index: [default_sort: [desc: :inserted_at]],
        show: [preload: [applications: [:delegate, :user, :certification, :certifiers]]]
      }
    end

    member_action :"override-current-user",
      &__MODULE__.override_current_user/2,
      label: "Connect as User",
      icon: "user"

    def override_current_user(conn, %{id: id}) do
      if Vae.Repo.get(Vae.User, id) do
        conn
        |> Plug.Conn.put_session(Application.get_env(:ex_admin, :override_user_id_session_key), id)
        |> Phoenix.Controller.redirect(external: Vae.User.profile_url(conn))
      else
        conn |> Phoenix.Controller.redirect(to: Routes.root_path(conn, :index))
      end
    end
  end
end
