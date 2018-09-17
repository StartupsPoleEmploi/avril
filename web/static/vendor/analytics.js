$(function(){
  function event_delegates_contact() {
    ga('send', 'event', 'Delegates', 'contact');
  };

  $('#footer_form').submit(event_delegates_contact);
  $('#contact_form').submit(event_delegates_contact);

  $("#previous-step").on("click", function() {
    ga('send', 'event', 'Steps', 'previous');
  });

  $("#next-step").on("click", function() {
    ga('send', 'event', 'Steps', 'next');
  });

  $("button.steps-print-button").on("click", function() {
    ga('send', 'event', 'Steps', 'print');
  });

  $(".delegate-details a[href]:not([href^='mailto:'])").on("click", function() {
    ga('send', 'event', 'Delegates', 'website');
  });

  $(".step p:contains('réunion') a").on("click", function() {
    ga('send', 'event', 'Delegates', 'information');
  });

  $(".step p:contains('ivret 1') a").on("click", function() {
    ga('send', 'event', 'Delegates', 'livret 1');
  });

  $(".step p:contains('ivret 2') a").on("click", function() {
    ga('send', 'event', 'Delegates', 'livret 2');
  });

  $(".step p a[href^='https://candidat.pole-emploi.fr']").on("click", function() {
    ga('send', 'event', 'Delegates', 'espace personnel');
  });
});
