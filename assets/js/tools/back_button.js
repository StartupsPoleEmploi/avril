import $ from 'jquery';

$(() => {

  $('a.is-back').on('click', e => {
    if (e.target.href === document.referrer || e.target.getAttribute('href') === '#') {
      console.log('Going back');
      history.back();
      e.preventDefault();
      return false;
    }
  });

});