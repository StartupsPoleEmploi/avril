import $ from 'jquery';

$(() => {
  $('a.is-back').on('click', e => {
    console.log(document.referrer)
    if (e.target.href === document.referrer || e.target.getAttribute('href') === '#') {
      console.log('Going back');
      history.back();
      e.preventDefault();
    }
    document.referrer === '' && window.close();
  });

});