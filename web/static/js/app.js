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

// import socket from "./socket"

import "awesomplete"
import "./smooth_scroll"

$(function () {
  $("body.home .wizard-step.complete a").on('click', function(e){
    e.preventDefault();
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

$(window).on('resize', function(){
  if ($(window).width() < 768 ) {
    $("#search_profession").attr("placeholder","Votre métier");
  } else {
    $("#search_profession").attr("placeholder","Pour quel métier souhaitez-vous un diplôme ?");	
  }
});
