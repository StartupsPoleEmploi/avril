import $ from 'jquery';
import autocomplete from '../tools/autocomplete.js';

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
    $submit.text("Message envoyé :)").removeAttr('disabled');
    },
    error: error => {
      const json = JSON.parse(error.responseText);
      $form.append(`<div class="alert alert-danger">${json.msg}</div>`);
      $submit.text("Message non envoyé :(").removeAttr('disabled');
    }
  });
});

autocomplete('#delegate_address');