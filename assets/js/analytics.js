import $ from 'jquery';

(() => {

  const naiveDeparam = queryString => {
    return queryString.replace(/^\??/, '').split('&')
  }

  const handleAnalyticsEvent = (target, element) => {
    if (!window.ga) return console.warn('Analytics not set up:', target, element);
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

  $.fn.elementAnalyticsEvent = function() {
    handleAnalyticsEvent($(this).attr('data-analytics'), this)
  }

  $.fn.listenToAnalyticsEvent = function() {
    $(this).filter((i, el) => !$(el).attr('[data-analytics]')).each((i, el) => {
      if ($(el).is('form')) {
        $(el).on('submit', e => {
          const $form = $(e.delegateTarget);
          if ($form.find('input[name]:not([data-analytics]):enabled').length) {
            $(el).elementAnalyticsEvent()
          }
        });
      } else if ($(el).is(':input') && $(el).parents('form').length > 1 && $(el).is(':not([type="submit"])')) {
        $(el).attr('data-original-value', $(el).val())
        const $form = $(el).parents('form');
        $form.on('submit', e => {
          if (($(el).val() && $(el).val() !== $(el).attr('data-original-value'))) {
            $(el).elementAnalyticsEvent()
          }
        });
      } else {
        $(el).on('click', e => {
          $(el).elementAnalyticsEvent()
        });
      }
    });
  }

  $('[data-analytics]').listenToAnalyticsEvent();

  $('.request-contact form').submit(() => {
    const contactData = $(this).serializeJSON();
    // if (contactData.contact_delegate) {
    //   handleAnalyticsEvent('Delegates#contact');
    // } else {
    //   handleAnalyticsEvent('Steps#email');
    // }
    if (contactData.booklet_1) {
      handleAnalyticsEvent('Steps#dossier inscription');
    }
  });

  $("#steps :contains('réunion') a").on('click', () => {
    handleAnalyticsEvent('Delegates#information');
  });

  $("#steps :contains('ivret 1') a").on('click', () => {
    handleAnalyticsEvent('Delegates#livret 1');
  });

  $("#steps :contains('ivret 2') a").on('click', () => {
    handleAnalyticsEvent('Delegates#livret 2');
  });

  $("#steps a[href^='https://candidat.pole-emploi.fr']").on('click', () => {
    handleAnalyticsEvent('Delegates#espace personnel');
  });


  if (window.location.hash.indexOf('ga=') > -1 ) {
    var command = window.location.hash.replace(/^#?ga=/, '')
    window.location.hash = '';
    handleAnalyticsEvent(command);
  }
})();

