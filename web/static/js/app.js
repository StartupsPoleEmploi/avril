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
import "bootstrap-select"
import "url-search-params"

$(function() {
  // Search labels
  $("<label class='form-control-placeholder form-control-lg-placeholder' for='search_profession' id='label_search_profession'>" + stepLabel($(window).width()) + "</label>").insertAfter("#search_profession");
  $("#search_profession").parent().addClass('form-label-group');
  $("<label class='form-control-placeholder form-control-lg-placeholder' for='search_geolocation_text' id='residence'>Votre ville de résidence</label>").insertAfter("#search_geolocation_text");
  $("#search_geolocation_text").parent().addClass('form-label-group');

  // Steps navigation
  var currentStep = 1;

  function prev_next(currentStep) {
    if ($('#step_' + (currentStep - 1)).length == 0) {
      $('#previous-step').parent().addClass('disabled');
    } else {
      $('#previous-step').parent().removeClass('disabled');
    }
    if ($('#step_' + (currentStep + 1)).length == 0) {
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

  // accessibility
  setTimeout(function() {
    // Ajout d'un aria pour aider à la compréhesion de l'utilité
    $('#algolia-places-listbox-0').attr('aria-labelledby', "residence");
    $('#algolia-places-listbox-0').attr('aria-selected', "false");
    // Ajout d'un aria atomic pour les aria assertive. A quoi çà sert ? Je ne sais pas.
    $("[aria-live='assertive']").attr('aria-atomic', 'true');
    // Ajout d'un aide à la compréhesion de qui controle quoi
    $('#search_geolocation_text').attr('aria-controls', 'algolia-places-listbox-0');

    $('#search_profession').attr('aria-controls', 'awesomplete_list_1');
    $('#search_profession').attr('aria-expanded', 'false');
    $('#search_profession').attr('aria-activedescendant', '');
    $('#search_profession').attr('aria-readonly', 'true');
    $('#search_profession').attr('autocomplete', 'off');

    $('#awesomplete_list_1').attr('aria-label', 'liste des métiers issus des RNCP');
    $('#awesomplete_list_1').attr('aria-selected', 'false');
  }, 200);

  var showChar = 300;
  var ellipsestext = "...";

  $(".truncate").each(function() {
    var content = $(this).html();
    if (content.length > showChar) {
      var c = content.substr(0, showChar);
      var h = content;
      var html =
        '<div class="truncate-text" style="display:block">' +
        c +
        '<span class="moreellipses">' +
        ellipsestext +
        '<br /><a href="" class="moreless more">Afficher la description <span class="ic-icon ic-small-triangle-down align-middle" /></a></span></span></div><div class="truncate-text" style="display:none">' +
        h +
        '<br /><a href="" class="moreless less">Masquer la description <span class="ic-icon rotate-180 ic-small-triangle-down align-middle" /></a></span></div>';

      $(this).html(html);
    }
  });

  $(".btn-history-back").click(function() {
    history.back();
  })

  $(".moreless").click(function() {
    var thisEl = $(this);
    var cT = thisEl.closest(".truncate-text");

    var tX = ".truncate-text";

    if (thisEl.hasClass("less")) {
      cT.prev(tX).toggle();
      cT.slideToggle(500);

      $('html, body').animate({
        scrollTop: thisEl.closest(".card-body").offset().top - 130
      }, 500);

    } else {
      cT.toggle();
      cT.next(tX).fadeToggle();
    }
    return false;
  });

  if (!sessionStorage.getItem('cookies_choice')) $('.cookies').removeClass('d-none');
  if (sessionStorage.getItem('cookies_choice') == 'reject') window.disableGa();

  $('.cookies .btn-reject').click(function() {
    sessionStorage.setItem('cookies_choice', 'reject')
    $('.cookies').addClass('d-none');
    window.disableGa();
  })

  $('.cookies .btn-primary').click(function() {
    sessionStorage.setItem('cookies_choice', 'accept');
    $('.cookies').addClass('d-none');
  })
})

$(window).scroll(function() {
  var y = $(window).scrollTop();
  if (y > 0) {
    $('.sticky-top').addClass('--not-top');
  } else {
    $('.sticky-top').removeClass('--not-top');
  }
});

$(window).on('resize', function() {
  $('#label_search_profession').text(stepLabel($(window).width()));
});

function stepLabel(width) {
  if (width < 768) {
    return "Votre métier";
  } else {
    return "Pour quel métier souhaitez-vous un diplôme ?";
  }
}