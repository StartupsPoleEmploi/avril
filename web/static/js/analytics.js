var handleAnalyticsEvent = function(target) {
  if (!window.ga) return console.warn("Analytics not set up:", target);
  if (!target) return console.warn("Target not correctly set");
  if (target.indexOf('?') === 0) {
    var queryString = naiveDeparam(window.location.search).concat(naiveDeparam(target)).join('&');
    ga('send', 'pageview', window.location.pathname + '?' + queryString);
  } else if (target.indexOf('/') === 0) {
    ga('send', 'pageview', target);
  } else {
    var cat_event = target.split('#');
    ga('send', 'event', cat_event[0], cat_event[1]);
  }
}

$(function() {

  $("[data-analytics]").each(function(i, el){
    if ($(el).is("form")) {
      $(el).on("submit", function(e){
        handleAnalyticsEvent($(e.delegateTarget).attr('data-analytics'))
      })
    } else {
      $(el).on("click", function(e){
        handleAnalyticsEvent($(e.delegateTarget).attr('data-analytics'))
      })
    }
  });

  $('.request-contact form').submit(function() {
    const contactData = $(this).serializeJSON();
    if (contactData.contact_delegate) {
      handleAnalyticsEvent('Delegates#contact');
    } else {
      handleAnalyticsEvent('Steps#email');
    }
    if (contactData.booklet_1) {
      handleAnalyticsEvent('Steps#dossier inscription');
    }
  });

  // $(".delegate-details a[href]:not([href^='mailto:'])").on("click", function() {
  //   ga('send', 'event', 'Delegates', 'website');
  // });

  $("#steps :contains('réunion') a").on("click", function() {
    handleAnalyticsEvent('Delegates#information')
  });

  $("#steps :contains('ivret 1') a").on("click", function() {
    handleAnalyticsEvent('Delegates#livret 1')
  });

  $("#steps :contains('ivret 2') a").on("click", function() {
    handleAnalyticsEvent('Delegates#livret 2')
  });

  $("#steps a[href^='https://candidat.pole-emploi.fr']").on("click", function() {
    handleAnalyticsEvent('Delegates#espace personnel')
  });


  if (window.location.hash.indexOf("ga=") > -1 ) {
    var command = window.location.hash.replace(/^#?ga=/, '')
    window.location.hash = '';
    handleAnalyticsEvent(command);
  }

});