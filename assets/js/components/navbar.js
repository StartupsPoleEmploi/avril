import $ from 'jquery';

$(() => {

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
});