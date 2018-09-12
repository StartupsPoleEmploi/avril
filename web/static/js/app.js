// Brunch automatically concatenates all files in your
// watched paths. Those paths can be configured at
// config.paths.watched in "brunch-config.js".
//
// However, those files will only be executed if
// explicitly imported. The only exception are files
// in vendor, which are never wrapped in imports and
// therefore are always executed.

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
import "phoenix_html"

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

import socket from "./socket"

import "awesomplete"
import "./smooth_scroll"

$(function () {
  // Search labels
  $("<label class='form-control-placeholder form-control-lg-placeholder' for='search_profession' id='label_search_profession'>" + stepLabel($(window).width()) + "</label>").insertAfter("#search_profession");
  $("#search_profession").parent().addClass('form-label-group');
  $("<label class='form-control-placeholder form-control-lg-placeholder' for='search_geolocation_text'>Votre ville de résidence</label>").insertAfter("#search_geolocation_text");
  $("#search_geolocation_text").parent().addClass('form-label-group');

  // Steps navigation
  var currentStep = 1;
  function prev_next(currentStep) {
    if($('#step_' + (currentStep - 1)).length == 0) {
      $('#previous-step').parent().addClass('disabled');
    } else {
      $('#previous-step').parent().removeClass('disabled');
    }
    if($('#step_' + (currentStep + 1)).length == 0) {
      $('#next-step').parent().addClass('disabled');
    } else {
      $('#next-step').parent().removeClass('disabled');
    }
  }
  $('#previous-step').click(function() {
    $('#step_' + currentStep).addClass("d-none");
    currentStep--;
    $('#step_' + currentStep).removeClass("d-none");
    prev_next(currentStep);
  });
  $('#next-step').click(function() {
    $('#step_' + currentStep).addClass("d-none");
    currentStep++;
    $('#step_' + currentStep).removeClass("d-none");
    prev_next(currentStep);
  });
})

$(window).scroll(function() {
  var y = $(window).scrollTop();
  if (y > 0) {
    $("nav").addClass('--not-top');
  } else {
    $("nav").removeClass('--not-top');
  }
});

$(window).on('resize', function() {
  $("#label_search_profession").text(stepLabel($(window).width()));
});

function stepLabel(width) {
  if (width < 768 ) {
    return "Votre métier";
  } else {
    return "Pour quel métier souhaitez-vous un diplôme ?";
  }
}
