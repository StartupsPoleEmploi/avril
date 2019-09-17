import '../css/admin.scss';

import he from 'he';
import places from 'places.js';
import './admin/tables';
import './admin/charts';
import './admin/statusEditor';


$(document).ready(() => {
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

  Simditor.locale = 'fr-FR';

  $("textarea[id^=process_step_]").each((i, $el) => {
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
})

const $filters = document.querySelector('form.filter_form');

if ($filters) {
  $filters.addEventListener('paste', (event) => {
    let paste = (event.clipboardData || window.clipboardData).getData('text');
    paste = paste.trim();
  });
}