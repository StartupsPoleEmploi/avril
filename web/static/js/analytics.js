class Analytics {
  init() {
    let self = this;

    $('[data-analytics]').each(function(i, el){
      if ($(el).is('form')) {
        $(el).on('submit', function(e){
          self.handleAnalyticsEvent($(e.delegateTarget).attr('data-analytics'), self)
        });
      } else {
        $(el).on('click', function(e){
          self.handleAnalyticsEvent($(e.delegateTarget).attr('data-analytics'), self)
        });
      }
    });

    $('.request-contact form').submit(function() {
      const contactData = $(this).serializeJSON();
      if (contactData.contact_delegate) {
        self.handleAnalyticsEvent('Delegates#contact', self);
      } else {
        self.handleAnalyticsEvent('Steps#email', self);
      }
      if (contactData.booklet_1) {
        self.handleAnalyticsEvent('Steps#dossier inscription', self);
      }
    });

    // $(".delegate-details a[href]:not([href^='mailto:'])").on("click", function() {
    //   window.ga('send', 'event', 'Delegates', 'website');
    // });

    $("#steps :contains('réunion') a").on('click', function() {
      self.handleAnalyticsEvent('Delegates#information', self);
    });

    $("#steps :contains('ivret 1') a").on('click', function() {
      self.handleAnalyticsEvent('Delegates#livret 1', self);
    });

    $("#steps :contains('ivret 2') a").on('click', function() {
      self.handleAnalyticsEvent('Delegates#livret 2', self);
    });

    $("#steps a[href^='https://candidat.pole-emploi.fr']").on('click', function() {
      self.handleAnalyticsEvent('Delegates#espace personnel', self);
    });


    if (window.location.hash.indexOf('ga=') > -1 ) {
      var command = window.location.hash.replace(/^#?ga=/, '')
      window.location.hash = '';
      self.handleAnalyticsEvent(command, self);
    }
  }

  handleAnalyticsEvent(target, self) {
    if (!window.ga) return console.warn('Analytics not set up:', target);
    if (!target) return console.warn('Target not correctly set');
    if (target.indexOf('?') === 0) {
      var queryString = self.naiveDeparam(window.location.search).concat(self.naiveDeparam(target)).join('&');
      window.ga('send', 'pageview', window.location.pathname + '?' + queryString);
    } else if (target.indexOf('/') === 0) {
      window.ga('send', 'pageview', target);
    } else {
      var categoryEvent = target.split('#');
      window.ga('send', 'event', categoryEvent[0], categoryEvent[1]);
    }
  }
  
  naiveDeparam(queryString) {
    return queryString.replace(/^\??/, '').split('&')
  }
}

export { Analytics };
