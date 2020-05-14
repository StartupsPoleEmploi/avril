import $ from 'jquery';

$(() => {
  const hiddenClass = 'is-hidden';
  const storageItem = 'cookies_choice';
  const $cookies = $('.cookies');
  const choice = localStorage.getItem(storageItem);
  if (!choice) {
    $cookies.removeClass(hiddenClass);
  } else {
    if (choice === 'reject') {
      window.disableGa();
    }
  }

  $('.cookies #reject-cookies').click(e => {
    localStorage.setItem(storageItem, 'reject')
    $cookies.addClass(hiddenClass);
    window.disableGa();
  })

  $('.cookies #accept-cookies').click(e => {
    localStorage.setItem(storageItem, 'accept');
    $cookies.addClass(hiddenClass);
  })

});