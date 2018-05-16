$(function(){
  $("a[href^='mailto:']").on("click", function () {
    ga('send', 'event', 'Delegates', 'contact');
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

  $(".card-body button.no-print").on("click", function() {
    ga('send', 'event', 'Delegates', 'print');
  });
});
