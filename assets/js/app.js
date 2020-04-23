import '../css/app.scss';

import 'phoenix_html';
import jQuery from 'jquery';
import 'bootstrap';
import 'bootstrap-select';
import 'url-search-params';

import './layout/index';

import './analytics';
import './tools/smooth_scroll';
import './components/button-toggle';
import './components/searchbar';
import './components/pagination';
import './components/level-selector';
import './pages/application';
import './pages/contact';
import './pages/financement';

window.jQuery = jQuery;
window.$ = jQuery;

$(() => {
  // Target blank on external links

  Array.from(document.getElementsByTagName('a')).forEach($link => {
    if ($link.hostname !== window.location.hostname && !$link.classList.contains('target-self')) {
      $link.setAttribute('target', '_blank');
    }
  });

  // Bootstrap extend
  $('[data-toggle="show"]').on('click', function(e){
    $($(e.target).attr('data-target')).toggleClass('d-none');
  });

  const disableButtons = $buttons => {
    $buttons.each((i, $button) => {
      const newContent = $($button).attr('data-disable-with');
      if (newContent) {
        $($button).text(newContent);
      }
      setTimeout(() => {
        $button.disabled = true;
      }, 0);
    });
  };

  const clickDisableSelector = `
    a[data-disable-with], a[data-disable],
    button[data-disable-with], button[type=submit][data-disable]
  `;
  const submitDisableSelector = `
    button[type=submit][data-disable-with], button[type=submit][data-disable],
    input[type=submit][data-disable-with], input[type=submit][data-disable]
  `;

  $(clickDisableSelector).on('click', e => {
    const $button = $(e.delegateTarget);
    if (!($($button).is('[type=submit]') && $($button).parents('form'))) {
      disableButtons($button)
    }
  })
  $('form').on('submit', e => {
    const $form = $(e.delegateTarget);
    const $buttons = $form.find(submitDisableSelector);
    if ($buttons.length) {
      disableButtons($buttons);
    }
  });


  $('a.is-back').on('click', e => {
    if (document.referrer !== document.location.href && document.referrer.indexOf(e.target.href) === 0) {
      console.log('Going back');
      history.back();
      e.preventDefault();
      return false;
    }
  })

  $('.app-status button.delete').on('click', e => {
    $(e.target).parents('.app-status').hide();
    $.ajax('/close-app-status', {
      method: 'POST',
      data: {
        _csrf_token: $(e.delegateTarget).attr('data-csrf'),
      }
    });
  });

  $('.navbar-burger.burger').on('click', e => {
    const $navbarMenu = $('.navbar-menu');
    if ($navbarMenu.hasClass('is-active')) {
      $navbarMenu.removeClass('is-active');
      $(e.target).removeClass('is-active');
    } else {
      $navbarMenu.addClass('is-active');
      $(e.target).addClass('is-active');
    }
  });

})