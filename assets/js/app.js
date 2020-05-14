// import '../css/app.scss';

import 'phoenix_html';
import jQuery from 'jquery';

import './tools/index';
import './components/index';
import './pages/index';

window.jQuery = jQuery;
window.$ = jQuery;

$(() => {
  $('.app-status button.delete').on('click', e => {
    $(e.target).parents('.app-status').hide();
    $.ajax('/close-app-status', {
      method: 'POST',
      data: {
        _csrf_token: $(e.delegateTarget).attr('data-csrf'),
      }
    });
  });

  $('.form.is-togglable').on('click', '.toggle-mode', e => {
    const $button = $(e.target);
    const $form = $(e.delegateTarget);
    $form.toggleClass('is-edit');
    if ($form.hasClass('is-edit')) {
      $form.find(':input[readonly]').removeAttr('readonly').each((i, el) => {
        $(el).attr('data-original-value', $(el).val())
      });
    } else {
      $form.find(':input').attr('readonly', 'readonly').each((i, el) => {
        $(el).val($(el).attr('data-original-value'))
      });
    }
    e.preventDefault();
    return
  })

})