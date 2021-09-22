import $ from 'jquery';
import typeahead from '../lib/typeahead.bundle.js';
import {debounce} from 'avril/js/utils/function';

export default (selector) => {
  const $input = $(selector);
  if ($input.length) {
    $input.typeahead({highlight: true}, {
      name: 'Address',
      async: true,
      display: result => result.properties.label,
      templates: {
        pending: e => (e.query.length > 5 ? 'Recherche ...' : ''),
        notFound: () => '<span>Aucun résultat</span>',
      },
      source: debounce((query, syncResults, asyncResults) => {
        if (!query.length > 5) return;
        syncResults([]);
        fetch(`https://api-adresse.data.gouv.fr/search/?q=${query}`)
          .then(fetched => fetched.json())
          .then(results => asyncResults(results.features))
          .catch(err => asyncResults([]))
      }, 500),
    });
  }
}