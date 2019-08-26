import '../css/app.scss';

import 'phoenix_html';
import jQuery from 'jquery';
import 'bootstrap';
import 'bootstrap-select';
import 'url-search-params';

import './analytics';
import './socket';
import './components/searchbar';
import './components/pagination';
import './components/level-selector';
import './pages/application';

window.jQuery = jQuery;
window.$ = jQuery;

$(() => {

  // Bootstrap extend
  $('[data-toggle="show"]').on('click', function(e){
    $($(e.target).attr('data-target')).toggleClass('d-none');
  });

  // Search labels
  $("<label class='form-control-placeholder form-control-lg-placeholder' for='search_query' id='label_search_query'>" + stepLabel($(window).width()) + "</label>").insertAfter("#search_query");
  $("#search_query").parent().addClass('form-label-group');
  $("<label class='form-control-placeholder form-control-lg-placeholder' for='search_geolocation_text' id='residence'>Votre ville de résidence</label>").insertAfter("#search_geolocation_text");
  $("#search_geolocation_text").parent().addClass('form-label-group');

  // accessibility
  setTimeout(function() {
    // Ajout d'un aria pour aider à la compréhesion de l'utilité
    $('#algolia-places-listbox-0').attr('aria-labelledby', "residence");
    $('#algolia-places-listbox-0').attr('aria-selected', "false");
    // Ajout d'un aria atomic pour les aria assertive. A quoi çà sert ? Je ne sais pas.
    $("[aria-live='assertive']").attr('aria-atomic', 'true');
    // Ajout d'un aide à la compréhesion de qui controle quoi
    $('#search_geolocation_text').attr('aria-controls', 'algolia-places-listbox-0');

    $('#search_query').attr('aria-controls', 'algolia-autocomplete-listbox-0');
    $('#search_query').attr('aria-activedescendant', '');
    $('#search_query').attr('aria-readonly', 'true');

    $('#algolia-autocomplete-listbox-0').attr('aria-label', 'liste des métiers ou diplomes');
    $('#algolia-autocomplete-listbox-0').attr('aria-selected', 'false');
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

  if (!localStorage.getItem('cookies_choice')) $('.cookies').removeClass('d-none');
  if (localStorage.getItem('cookies_choice') == 'reject') window.disableGa();

  $('.cookies .btn-reject').click(function() {
    localStorage.setItem('cookies_choice', 'reject')
    $('.cookies').addClass('d-none');
    window.disableGa();
  })

  $('.cookies .btn-primary').click(function() {
    localStorage.setItem('cookies_choice', 'accept');
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
  $('#label_search_query').text(stepLabel($(window).width()));
});

function stepLabel(width) {
  if (width < 768) {
    return "Votre métier";
  } else {
    return "Tapez le métier pour lequel vous souhaitez obtenir un diplôme";
  }
}