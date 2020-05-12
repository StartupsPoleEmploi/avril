defmodule VaeWeb.Mutation.ApplicationTest do
  use VaeWeb.ConnCase, async: true

  import Swoosh.TestAssertions

  setup %{conn: conn} do
    ExMachina.Sequence.reset()

    user = insert(:user)

    authed_conn = Pow.Plug.assign_current_user(conn, user, otp_app: :vae)

    {:ok, conn: authed_conn}
  end

  @query """
  mutation AttachDelegate ($input: AttachDelegateInput!) {
    attachDelegate(input: $input) {
      id
      delegate {
        id
        name
      }
    }
  }
  """
  test "Link a delegate to an application", %{conn: conn} do
    application =
      insert(
        :application_without_delegate,
        %{user: conn.assigns[:current_user]}
      )

    delegate = insert(:delegate)

    attach_delegate_input = %{
      "applicationId" => application.id,
      "delegateId" => delegate.id
    }

    conn =
      post(conn, "/api/v2",
        query: @query,
        variables: %{"input" => attach_delegate_input}
      )

    assert json_response(conn, 200) ==
             %{
               "data" => %{
                 "attachDelegate" => %{
                   "id" => "#{application.id}",
                   "delegate" => %{
                     "id" => "#{delegate.id}",
                     "name" => delegate.name
                   }
                 }
               }
             }
  end

  @query """
  mutation AttachDelegate ($input: AttachDelegateInput!) {
    attachDelegate(input: $input) {
      id
      delegate {
        id
        name
      }
    }
  }
  """
  test "Try to link a delegate to an unknown application fails", %{conn: conn} do
    attach_delegate_input = %{
      "applicationId" => 0,
      "delegateId" => -1
    }

    conn =
      post(conn, "/api/v2",
        query: @query,
        variables: %{"input" => attach_delegate_input}
      )

    assert json_response(conn, 200) ==
             %{
               "data" => %{"attachDelegate" => nil},
               "errors" => [
                 %{
                   "details" => "Application id 0 not found",
                   "locations" => [%{"column" => 0, "line" => 2}],
                   "message" => "La candidature est introuvable",
                   "path" => ["attachDelegate"]
                 }
               ]
             }
  end

  @query """
  mutation AttachDelegate ($input: AttachDelegateInput!) {
    attachDelegate(input: $input) {
      id
      delegate {
        id
        name
      }
    }
  }
  """
  test "Try to link an unknown delegate to an application fails", %{conn: conn} do
    application =
      insert(
        :application_without_delegate,
        %{user: conn.assigns[:current_user]}
      )

    attach_delegate_input = %{
      "applicationId" => application.id,
      "delegateId" => 0
    }

    conn =
      post(conn, "/api/v2",
        query: @query,
        variables: %{"input" => attach_delegate_input}
      )

    assert json_response(conn, 200) ==
             %{
               "data" => %{"attachDelegate" => nil},
               "errors" => [
                 %{
                   "details" => "Delegate id 0 not found",
                   "locations" => [%{"column" => 0, "line" => 2}],
                   "message" => "Le certificateur est introuvable",
                   "path" => ["attachDelegate"]
                 }
               ]
             }
  end

  @query """
  mutation RegisterMeeting ($input: RegisterMeetingInput!) {
    registerMeeting(input: $input) {
      id
      meeting {
        name
        meetingId
        place
        address
        postalCode
        city
        startDate
        endDate
      }
    }
  }
  """
  test "Register to a meeting with no meeting id fails", %{conn: conn} do
    application =
      insert(
        :application,
        %{user: conn.assigns[:current_user]}
      )

    conn =
      post(conn, "/api/v2",
        query: @query,
        variables: %{"input" => %{"applicationId" => application.id, "meetingId" => ""}}
      )

    assert json_response(conn, 200) ==
             %{
               "data" => %{"registerMeeting" => nil},
               "errors" => [
                 %{
                   "details" => "Meeting ID must be provided",
                   "locations" => [%{"column" => 0, "line" => 2}],
                   "message" => "La prise de rendez-vous a échoué",
                   "path" => ["registerMeeting"]
                 }
               ]
             }
  end

  @query """
  mutation RegisterMeeting ($input: RegisterMeetingInput!) {
    registerMeeting(input: $input) {
      id
      meeting {
        name
        meetingId
        place
        address
        postalCode
        city
        startDate
        endDate
      }
    }
  }
  """
  test "Register to a meeting with incomplete user informations fails", %{conn: conn} do
    application =
      insert(
        :application,
        %{user: conn.assigns[:current_user]}
      )

    conn =
      post(conn, "/api/v2",
        query: @query,
        variables: %{"input" => %{"applicationId" => application.id, "meetingId" => "success"}}
      )

    assert json_response(conn, 200) ==
             %{
               "data" => %{"registerMeeting" => nil},
               "errors" => [
                 %{
                   "locations" => [%{"column" => 0, "line" => 2}],
                   "message" => "La prise de rendez-vous a échoué",
                   "path" => ["registerMeeting"],
                   "details" => [
                     %{"key" => "birthday", "message" => ["can't be blank"]},
                     %{"key" => "city_label", "message" => ["can't be blank"]},
                     %{"key" => "country_label", "message" => ["can't be blank"]}
                     # %{"key" => "email_confirmed_at", "message" => ["can't be blank"]}
                   ]
                 }
               ]
             }
  end

  @query """
  mutation RegisterMeeting ($input: RegisterMeetingInput!) {
    registerMeeting(input: $input) {
      id
      meeting {
        name
        meetingId
        place
        address
        postalCode
        city
        startDate
        endDate
      }
    }
  }
  """
  test "Register to a meeting", %{conn: conn} do
    user =
      conn.assigns[:current_user]
      |> Ecto.Changeset.change(%{
        birthday: ~D[2002-04-05],
        city_label: "Paris",
        country_label: "FR"
        # email_confirmed_at: Timex.now() |> DateTime.truncate(:second)
      })
      |> Vae.Repo.update!()

    application =
      insert(
        :application,
        %{user: user}
      )

    conn =
      post(conn, "/api/v2",
        query: @query,
        variables: %{"input" => %{"applicationId" => application.id, "meetingId" => "success"}}
      )

    assert json_response(conn, 200) ==
             %{
               "data" => %{
                 "registerMeeting" => %{
                   "id" => "#{application.id}",
                   "meeting" => %{
                     "address" => "502  Raccoon Run",
                     "city" => "Seattle",
                     "endDate" => "2020-04-01T12:30:00",
                     "meetingId" => "12345",
                     "name" => "The place 2 be",
                     "place" => "Serioulsy this is the place 2 be",
                     "postalCode" => "98115",
                     "startDate" => "2020-04-01T10:00:00"
                   }
                 }
               }
             }

    assert_email_sent(
      Vae.Repo.get(Vae.UserApplication, application.id)
      |> VaeWeb.ApplicationEmail.user_submission_confirmation()
    )
  end

  @query """
    mutation UploadResume($id: ID!){ uploadResume(id: $id, resume: "fake_resume") }
  """
  test "Upload Resume", %{conn: conn} do
    user = conn.assigns[:current_user]

    application =
      insert(
        :application,
        %{user: user}
      )

    upload = %Plug.Upload{
      content_type: "application/pdf",
      filename: "fake_resume.pdf",
      path: Path.expand("../../fixtures/fake_resume.pdf", __DIR__)
    }

    upload_conn =
      conn
      |> Plug.Conn.put_req_header("content-type", "multipart/form-data")
      |> post(
        "/api/v2",
        %{"query" => @query, "fake_resume" => upload, "variables" => %{"id" => application.id}}
      )

    assert json_response(upload_conn, 200) == %{"data" => %{"uploadResume" => "success"}}

    query = """
        query ($id: ID!){
          application(id: $id) {
            id
            resumes {
              content_type
              filename
              url
            }
          }
        }
    """

    conn = get conn, "/api/v2", query: query, variables: %{"id" => application.id}

    assert json_response(conn, 200) == %{
             "data" => %{
               "application" => %{
                 "id" => "#{application.id}",
                 "resumes" => [
                   %{
                     "content_type" => "application/pdf",
                     "filename" => "fake_resume.pdf",
                     "url" => "http://localhost/#{application.id}/fake_resume.pdf"
                   }
                 ]
               }
             }
           }
  end
end
