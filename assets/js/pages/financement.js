import $ from 'jquery';

$('select.situation-select').on('change', e => {
  $('.situation-descriptions .collapse').collapse('hide');
  $('.situation-descriptions .collapse[data-name='+e.target.value+']').collapse('show');
});