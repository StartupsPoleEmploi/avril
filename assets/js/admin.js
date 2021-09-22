/* global $ */

import he from 'he';
import './admin/tables';
import './admin/charts';
import './admin/pies';
import './admin/statusEditor';
import autocomplete from './tools/autocomplete';

function debounce(func, wait, immediate) {
  var timeout;
  return function() {
    var context = this, args = arguments;
    var later = function() {
      timeout = null;
      if (!immediate) func.apply(context, args);
    };
    var callNow = immediate && !timeout;
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
    if (callNow) func.apply(context, args);
  };
};

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

  const isMatching = (field, query) => {
    return field.toLowerCase().replace(/\s/, ' ').includes(query.toLowerCase().replace(/\s/, ' '))
  }

  const addSearchField = ($input, selector) => {
    $input.on('keydown', debounce(e => {
      const searchField = e.target.value;
      const values = $(selector).each((i, el) => {
        if (searchField && !isMatching($(el).text(), searchField)) {
          $(el).addClass('hidden');
        } else {
          $(el).removeClass('hidden');
        }
      });
    }, 500));
  };

  const resetSearch = that => {
    $(`#${that.$container.attr('id')} .ms-elem-selectable:not(.ms-selected)`).removeClass('hidden');
    $(`#${that.$container.attr('id')} .ms-elem-selection.ms-selected`).removeClass('hidden');
    that.$selectableUl.next().val('');
    that.$selectionUl.next().val('');
  }

  const input = '<input type="text" class="search form-control" autocomplete="off" placeholder="Filter ...">';

  const labelize = label => `<p><strong>${label}</strong></p>`;

  $('section.content form select[multiple]').each((i, el) => {

    $(el).multiSelect({
      selectableHeader: labelize($(el).attr('data-selectable')),
      selectionHeader: labelize($(el).attr('data-selection')),
      selectableFooter: input,
      selectionFooter: input,
      afterInit: function(ms){
        addSearchField(this.$selectableUl.next(), `#${this.$container.attr('id')} .ms-elem-selectable:not(.ms-selected)`);
        addSearchField(this.$selectionUl.next(), `#${this.$container.attr('id')} .ms-elem-selection.ms-selected`);
      },
    });
  })
}

const autocompleteDelegateAddress = () => autocomplete('input#delegate_address');
// {
//   const $input = $('input#delegate_address');
//   if ($input.length) {
//     $input.typeahead({highlight: true}, {
//       name: 'Address',
//       async: true,
//       display: result => result.properties.label,
//       templates: {
//         pending: e => (e.query.length > 5 ? 'Searching ...' : ''),
//         notFound: () => '<span>No results (<a href="https://adresse.data.gouv.fr/base-adresse-nationale" target="_blank">Verify</a>)</span>',
//       },
//       source: debounce((query, syncResults, asyncResults) => {
//         if (!query.length > 5) return;
//         syncResults([]);
//         fetch(`https://api-adresse.data.gouv.fr/search/?q=${query}`)
//           .then(fetched => fetched.json())
//           .then(results => asyncResults(results.features))
//           .catch(err => asyncResults([]))
//       }, 500),
//     });
//   }
// }

$(document).ready(() => {
  addDelegateGeolocationMap();
  textareaToSimditor();
  selectFiltersWithChosen();
  selectMultipleWithMultiSelect();
  trimPaste();
  doubleClickUncheckPresenceRadioInputs();
  autocompleteDelegateAddress();
})

