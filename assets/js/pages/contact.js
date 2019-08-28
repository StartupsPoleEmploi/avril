import $ from 'jquery';

$('#contact-form').on('submit', e => {
  e.preventDefault();
  const $form = $(e.target);
  const $submit = $form.find("[type=submit]");
  console.log($form);
  $submit.attr("disabled", "disabled").text("Envoi en cours ...");
  $.ajax({
    type: 'POST',
    url: $form.attr('action'),
    data: $form.serialize(),
    success: data => {
    $form.append(`<div class="alert alert-success">${data.msg}</div>`);
    $submit.text("Message envoyé :)");
    },
    error: error => {
      const json = JSON.parse(error.responseText);
      $form.append(`<div class="alert alert-danger">${json.msg}</div>`);
      $submit.text("Message non envoyé :(");
    }
  });
});