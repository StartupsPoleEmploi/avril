defmodule VaeWeb.Mutation.ResumeTest do
  use VaeWeb.ConnCase, async: true

  setup %{conn: conn} do
    ExMachina.Sequence.reset()

    user = insert(:user)

    authed_conn = Pow.Plug.assign_current_user(conn, user, otp_app: :vae)

    {:ok, conn: authed_conn}
  end

  @query """
    mutation DeleteResume($id: ID!){
      deleteResume(id: $id){
        id
      }
    }
  """
  test "Delete Resume", %{conn: conn} do
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

    insert_query = """
      mutation UploadResume($id: ID!){
        uploadResume(id: $id, resume: "fake_resume") {
          id
        }
      }
    """

    upload_conn =
      conn
      |> Plug.Conn.put_req_header("content-type", "multipart/form-data")
      |> post(
        "/api/v2",
        %{
          "query" => insert_query,
          "fake_resume" => upload,
          "variables" => %{"id" => application.id}
        }
      )

    assert json_response(upload_conn, 200) ==
             %{
               "data" => %{
                 "uploadResume" => %{
                   "id" => "#{application.id}"
                 }
               }
             }

    resume = Vae.Repo.get_by(Vae.Resume, application_id: application.id)
    assert not is_nil(resume)

    delete_conn =
      conn
      |> post("/api/v2",
        query: @query,
        variables: %{"id" => resume.id}
      )

    assert json_response(delete_conn, 200) ==
             %{
               "data" => %{
                 "deleteResume" => %{
                   "id" => "#{resume.id}"
                 }
               }
             }

    query = """
        query ($id: ID!){
          application(id: $id) {
            id
            resumes {
              id
            }
          }
        }
    """

    conn = get conn, "/api/v2", query: query, variables: %{"id" => application.id}

    assert json_response(conn, 200) == %{
             "data" => %{
               "application" => %{
                 "id" => "#{application.id}",
                 "resumes" => []
               }
             }
           }
  end
end
