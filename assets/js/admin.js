/* global $ */
import '../css/admin.scss';

import 'chosen-js';
import 'chosen-js/chosen.css';

import he from 'he';
import places from 'places.js';
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

const algoliaAutocompleteDelegateAddress = () => {
  if(document.querySelector('#delegate_address')) {
    var placesAutocomplete = places({
      appId: window.algolia_places_app_id,
      apiKey: window.algolia_places_api_key,
      container: document.querySelector('#delegate_address'),
      language: 'fr',
      countries: ['fr'],
      templates: {
        value: ({ name, postcode, city }) => city ? `${name} ${postcode} ${city}` : `${postcode} ${name}`
      }
    });

    placesAutocomplete.on('change', function(e) {
      delegate_geo.value = JSON.stringify(e.suggestion.hit);
    });

    placesAutocomplete.on('clear', function() {
      delegate_geo.value = '';
    });
  }
}

const textareaToSimditor = () => {
  Simditor.locale = 'fr-FR';

  $('textarea').each((i, $el) => {
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
        'table',
        'link',
        'hr',
        'indent',
        'outdent',
        'alignment'
      ],
      toolbarFloat: false,
      defaultImage: 'http://temp.im/150x150'
    });
  });
}

const selectFiltersWithChosen = () => {
  $('form.filter_form select.form-control').chosen();
}

$(document).ready(() => {
  algoliaAutocompleteDelegateAddress();
  textareaToSimditor();
  selectFiltersWithChosen();
  trimPaste();
  doubleClickUncheckPresenceRadioInputs();
})

