import $ from 'jquery';

$('select.situation-select').on('change', e => {
  $('.situation-descriptions .option').addClass('is-hidden');
  $('.situation-descriptions .option[data-name='+e.target.value+']').removeClass('is-hidden');
});