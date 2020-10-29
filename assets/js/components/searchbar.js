import $ from 'jquery';
import algoliasearch from 'algoliasearch';
import autocomplete from 'autocomplete.js';

const ipNumber = iPaddress => {
  const ip = iPaddress.match(/^(\d+)\.(\d+)\.(\d+)\.(\d+)$/);
  if(ip) {
    return (+ip[1]<<24) + (+ip[2]<<16) + (+ip[3]<<8) + (+ip[4]);
  }
}

const ipMask = maskSize => {
  return -1<<(32-maskSize);
}

const isInSubnet = (ip, subnetIp, subnetMask) => {
  return (ipNumber(ip) & ipMask(subnetMask)) === ipNumber(subnetIp);
}

const clientOptionsWithProxy = (key, needProxy) => {
  return needProxy ? {
    hosts: [`algolia-${key}.beta.pole-emploi.fr`]
  } : null;
}

const setupSearchBar = needProxy => {
  const client = algoliasearch(
    window.algolia_app_id,
    window.algolia_search_api_key,
    clientOptionsWithProxy(window.algolia_app_id, needProxy)
  );

  const professionToPath = suggestion => `/diplomes?metier=${suggestion.id}-${suggestion.slug}`
  const certificationToPath = suggestion => `/diplomes/${suggestion.id}-${suggestion.slug}`

  autocomplete('#search_query', {
    ariaLabel: 'Cherchez un métier ou un diplôme',
    autoselect: true,
    autoselectOnBlur: true,
    cssClasses: {
      prefix: 'avril'
    },
    minLength: 3,
  }, [{
    source: autocomplete.sources.hits(client.initIndex('profession'), {
      hitsPerPage: 5,
      queryType: 'prefixAll',
    }),
    displayKey: suggestion => suggestion.label,
    debounce: 500,
    templates: {
      header: '<h5 class="title">Métiers</div>',
      suggestion: suggestion => `<a href="${professionToPath(suggestion)}">${suggestion._highlightResult.label.value}</a>`,
    }
  }, {
    source: autocomplete.sources.hits(client.initIndex('certification'), {
      hitsPerPage: 3,
      queryType: 'prefixAll',
      facetFilters: 'is_active:true',
    }),
    debounce: 500,
    displayKey: suggestion => {
      const acronym = suggestion.acronym;
      const label = suggestion.label;
      return acronym ? `${acronym} ${label}` : label;
    },
    templates: {
      header: '<h5 class="title">Dîplomes</div>',
      suggestion: suggestion => {
        const acronym = suggestion._highlightResult.acronym && suggestion._highlightResult.acronym.value;
        const label = suggestion._highlightResult.label.value;
        const value = acronym ? `${acronym} ${label}` : label;
        return `<a href="${certificationToPath(suggestion)}">${value}</a>`;
      }
    }
  }])
  .on('ready', e => {
    setupLabelsAndAccessibility();
  })
  .on('autocomplete:selected', (event, suggestion, datasetIndex) => {
    window.location.href = datasetIndex === 1 ? professionToPath(suggestion) : certificationToPath(suggestion);
  });
}

const setupLabelsAndAccessibility = () => {
  $('#certification_finder label.label').insertAfter($('#certification_finder input.avril-input[type=search]'));
  // Ajout d'un aria pour aider à la compréhesion de l'utilité
  $('#algolia-places-listbox-0').attr('aria-labelledby', "residence");
  $('#algolia-places-listbox-0').attr('aria-selected', "false");
  // Ajout d'un aria atomic pour les aria assertive. A quoi çà sert ? Je ne sais pas.
  $("[aria-live='assertive']").attr('aria-atomic', 'true');
  // Ajout d'un aide à la compréhesion de qui controle quoi
  $('#search_geolocation_text').attr('aria-controls', 'algolia-places-listbox-0');

  $('#search_query').attr('aria-controls', 'algolia-autocomplete-listbox-0');
  $('#search_query').attr('aria-activedescendant', '');
  $('#search_query').attr('aria-readonly', 'true');

  $('#algolia-autocomplete-listbox-0').attr('aria-label', 'liste des métiers ou diplômes');
  $('#algolia-autocomplete-listbox-0').attr('aria-selected', 'false');
}

$(() => {
  if ($('#certification_finder').length) {
    let needProxy = false;
    $.get('https://api.ipify.org')
    .done(ip => {
      needProxy = isInSubnet(ip, '185.215.64.0', '22');
    })
    .fail(() => {
      needProxy = true;
    })
    .always(() => {
      console.log('Proxy set ? ', needProxy);
      setupSearchBar(needProxy);
    });

  }
});
