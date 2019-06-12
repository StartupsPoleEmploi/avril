import '../css/admin.scss';

import '../vendor/admin_lte2.js';
import '../vendor/simditor.js';
import 'jquery.multi-select.js';

$(document).ready(function() {
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

  Simditor.locale = 'en-US';

  if ($("[id^=process_step_]").length) {
    var i;
    for (i = 1; i < 9; i++) {
      var editor = new Simditor({
        textarea: $('#process_step_' + i),
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
    }
  }
})

const $filters = document.querySelector('form.filter_form');

$filters.addEventListener('paste', (event) => {
  let paste = (event.clipboardData || window.clipboardData).getData('text');
  paste = paste.trim();
});