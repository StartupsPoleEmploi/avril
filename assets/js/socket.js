// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "web/static/js/app.js".

import $ from "jquery";
import 'jquery-serializejson'

// To use Phoenix channels, the first step is to import Socket
// and connect at the socket path in "lib/my_app/endpoint.ex":
import {
  Socket
} from "phoenix"

let socket = new Socket("/socket", {
  params: {
    token: window.userToken
  }
})

// When you connect, you'll often need to authenticate the client.
// For example, imagine you have an authentication plug, `MyAuth`,
// which authenticates the session and assigns a `:current_user`.
// If the current user exists you can assign the user's token in
// the connection for use in the layout.
//
// In your "web/router.ex":
//
//     pipeline :browser do
//       ...
//       plug MyAuth
//       plug :put_user_token
//     end
//
//     defp put_user_token(conn, _) do
//       if current_user = conn.assigns[:current_user] do
//         token = Phoenix.Token.sign(conn, "user socket", current_user.id)
//         assign(conn, :user_token, token)
//       else
//         conn
//       end
//     end
//
// Now you need to pass this token to JavaScript. You can do so
// inside a script tag in "web/templates/layout/app.html.eex":
//
//     <script>window.userToken = "<%= assigns[:user_token] %>";</script>
//
// You will need to verify the user token in the "connect/2" function
// in "web/channels/user_socket.ex":
//
//     def connect(%{"token" => token}, socket) do
//       # max_age: 1209600 is equivalent to two weeks in seconds
//       case Phoenix.Token.verify(socket, "user socket", token, max_age: 1209600) do
//         {:ok, user_id} ->
//           {:ok, assign(socket, :user, user_id)}
//         {:error, reason} ->
//           :error
//       end
//     end
//
// Finally, pass the token on connect as below. Or remove it
// from connect if you don't care about authentication.

socket.connect()

// Contact form
function contact(event) {
  // Now that you are connected, you can join channels with a topic:
  let channel = socket.channel("contact:send", {})
  channel.join()
  $(event.target).find('button[type=submit]').prop('disabled', true)
  var contactData = $(event.target).serializeJSON()
  event.preventDefault()
  channel.push("contact_request", {
      body: Object.assign({}, contactData, {
        delegate: window.delegate,
        certification: window.certification,
        job: window.profession,
        county: window.county
      })
    })
    .receive("ok", function() {
      $('.request-contact').addClass('d-none')
      $('.result-contact').removeClass('d-none')
      channel.leave()
    })
    // Not working.
    // TODO: plug this
    // .receive("timeout", () => console.log("Networking issue...") )
    // .receive("phx_error", function() {
    //   $(event.target).find('button[type=submit]').prop('disabled', false)
    //   $(event.target).append('<p class="alert alert-error">Une erreur est survenue, merci de réessayer plus tard.</p>')
    // })

};

$(function() {
  $('form.contact-form').submit(contact)
});

export default socket