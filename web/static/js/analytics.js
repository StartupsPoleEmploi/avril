class Analytics {
  init() {
    let analytics = this
    $('[data-analytics]').each(function(i, el){
      if ($(el).is('form')) {
        $(el).on('submit', function(e){
          analytics.handleAnalyticsEvent($(e.delegateTarget).attr('data-analytics'))
        });
      } else {
        $(el).on('click', function(e){
          analytics.handleAnalyticsEvent($(e.delegateTarget).attr('data-analytics'))
        });
      }
    });

    $('.request-contact form').submit(function() {
      const contactData = $(this).serializeJSON();
      if (contactData.contact_delegate) {
        analytics.handleAnalyticsEvent('Delegates#contact');
      } else {
        analytics.handleAnalyticsEvent('Steps#email');
      }
      if (contactData.booklet_1) {
        analytics.handleAnalyticsEvent('Steps#dossier inscription');
      }
    });

    // $(".delegate-details a[href]:not([href^='mailto:'])").on("click", function() {
    //   window.ga('send', 'event', 'Delegates', 'website');
    // });

    $("#steps :contains('réunion') a").on('click', function() {
      analytics.handleAnalyticsEvent('Delegates#information');
    });

    $("#steps :contains('ivret 1') a").on('click', function() {
      analytics.handleAnalyticsEvent('Delegates#livret 1');
    });

    $("#steps :contains('ivret 2') a").on('click', function() {
      analytics.handleAnalyticsEvent('Delegates#livret 2');
    });

    $("#steps a[href^='https://candidat.pole-emploi.fr']").on('click', function() {
      analytics.handleAnalyticsEvent('Delegates#espace personnel');
    });


    if (window.location.hash.indexOf('ga=') > -1 ) {
      var command = window.location.hash.replace(/^#?ga=/, '')
      window.location.hash = '';
      analytics.handleAnalyticsEvent(command);
    }
  }

  handleAnalyticsEvent(target) {
    if (!window.ga) return console.warn('Analytics not set up:', target);
    if (!target) return console.warn('Target not correctly set');
    if (target.indexOf('?') === 0) {
      var queryString = naiveDeparam(window.location.search).concat(naiveDeparam(target)).join('&');
      window.ga('send', 'pageview', window.location.pathname + '?' + queryString);
    } else if (target.indexOf('/') === 0) {
      window.ga('send', 'pageview', target);
    } else {
      var categoryEvent = target.split('#');
      window.ga('send', 'event', categoryEvent[0], categoryEvent[1]);
    }
  }
};

export { Analytics };
