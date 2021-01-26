/* global $ */

import 'chosen-js';
import 'chosen-js/chosen.css';

import he from 'he';
import './admin/tables';
import './admin/charts';
import './admin/statusEditor';

const trimPaste = () => {
  const $filters = document.querySelector('form.filter_form');

  if ($filters) {
    $filters.addEventListener('paste', (event) => {
      let paste = (event.clipboardData || window.clipboardData).getData('text');
      paste = paste.trim();
    });
  }
}

const clearSelection = () => {
  if(document.selection && document.selection.empty) {
      document.selection.empty();
  } else if(window.getSelection) {
      var sel = window.getSelection();
      sel.removeAllRanges();
  }
}

const doubleClickUncheckPresenceRadioInputs = () => {
  $('form.filter_form .label.with-null-filter .label-inline').on('dblclick', e => {
    $(e.currentTarget).find('input[type=radio]').removeAttr('checked');
    clearSelection();
  });
}

const addDelegateGeolocationMap = () => {
  if (!document.getElementById('delegate_map')) return;
  const dataset = document.getElementById('delegate_map').dataset;
  const delegateMap = L.map('delegate_map', {
    center: [dataset.lat, dataset.lng],
    zoom: 13,
  });

  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    maxZoom: 20,
    id: 'mapbox.streets'
  }).addTo(delegateMap);

  L.marker([dataset.lat, dataset.lng]).addTo(delegateMap);
}

const textareaToSimditor = () => {
  Simditor.locale = 'fr-FR';

  $('textarea:not([readonly])').each((i, $el) => {
    $($el).val(he.decode($($el).val()))
    new Simditor({
      textarea: $($el),
      toolbar: [
        'title',
        'bold',
        'italic',
        'underline',
        'strikethrough',
        'ol',
        'ul',
        'blockquote',
        'link',
        'hr',
        'image'
      ],
      toolbarFloat: false,
      defaultImage: 'http://temp.im/150x150'
    });
  });
}

const selectFiltersWithChosen = () => {
  $('form.filter_form select.form-control').chosen();
}

const selectMultipleWithMultiSelect = () => {
  $('section.content form select[multiple]').multiSelect({
    selectableHeader: ' : all possible choices',
    selectionHeader: ' : actually selected choices'
  });
}

$(document).ready(() => {
  addDelegateGeolocationMap();
  textareaToSimditor();
  selectFiltersWithChosen();
  selectMultipleWithMultiSelect();
  trimPaste();
  doubleClickUncheckPresenceRadioInputs();
})

