import $ from 'jquery';

$(() => {
  $('a.is-back').on('click', e => {
    if (e.target.href === document.referrer || e.target.getAttribute('href') === '#') {
      console.log('Going back');
      const result = history.back();
      e.preventDefault();
      // If link was opened in a new tab, document.referrer is set, but history.back() doesn't work :(
      // Unfortunately there is no way to be aware of this situation
      setTimeout(function(){
        window.location.href = document.referrer;
      }, 1000);
    }
    document.referrer === '' && window.close();
  });

});