import $ from 'jquery';
import places from 'places.js';
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
  const professions = client.initIndex('profession');
  const certifications = client.initIndex('certification');
  autocomplete('#search_query', {
    autoselect: true,
    autoselectOnBlur: true,
    cssClasses: {
      prefix: 'ap'
    }
  }, [{
    source: autocomplete.sources.hits(professions, { hitsPerPage: 5, queryType: 'prefixAll' }),
    displayKey: suggestion => suggestion.label,
    templates: {
      header: '<h5 class="m-0 ap-suggestions-category">Métiers</div>',
      suggestion: suggestion => suggestion._highlightResult.label.value,
    }
  }, {
    source: autocomplete.sources.hits(certifications, { hitsPerPage: 3, queryType: 'prefixAll' }),
    displayKey: suggestion => {
      const acronym = suggestion.acronym;
      const label = suggestion.label;
      return acronym ? `${acronym} ${label}` : label;
    },
    templates: {
      header: '<h5 class="m-0 ap-suggestions-category">Dîplomes</div>',
      suggestion: suggestion => {
        const acronym = suggestion._highlightResult.acronym && suggestion._highlightResult.acronym.value;
        const label = suggestion._highlightResult.label.value;
        return acronym ? `${acronym} ${label}` : label;
      }
    }

  }]).on('autocomplete:selected', (event, suggestion, dataset) => {
     if(dataset === 1) {
      $('#search_rome_code').val(suggestion.rome_code);
       $('#search_certification').val('');
     }
     if(dataset === 3) {
      $('#search_rome_code').val(suggestion.code);
       $('#search_certification').val('');
     }
     if(dataset === 2) {
      $('#search_rome_code').val('');
       $('#search_certification').val(suggestion.id);
     }
  });

  const places = algoliasearch.initPlaces(
    window.algolia_places_app_id,
    window.algolia_places_api_key,
    clientOptionsWithProxy('places', needProxy)
  );

  const updateForm = response => {
    const hits = response.hits;
    const suggestion = hits[0];

    if (suggestion && suggestion.locale_names && suggestion.city) {
      $('#search_geolocation_text').val(suggestion.is_city ? suggestion.locale_names[0] : suggestion.city[0]);
      $('#search_county').val(suggestion.county || suggestion.city || suggestion.name);
      $('#search_postcode').val(suggestion.postcode);
      $('#search_administrative').val(suggestion.administrative);
    }

    $('#locate-me .fa-refresh').addClass('d-none');
    $('#locate-me .ic-icon').removeClass('d-none');
  }

  $('#locate-me').on('click', () => {
    $('#locate-me .fa-refresh').removeClass('d-none');
    $('#locate-me .ic-icon').addClass('d-none');
    navigator.geolocation.getCurrentPosition(response => {
      const coords = response.coords;
      const lat = coords.latitude.toFixed(6);
      const lng = coords.longitude.toFixed(6);

      $('#search_lat').val(lat);
      $('#search_lng').val(lng);

      places.reverse({
        aroundLatLng: `${lat},${lng}`,
        language: 'fr',
        hitsPerPage: 1
      }).then(updateForm);
    }, () => {
      $('#locate-me').addClass('d-none');
      $('#locate-me').removeClass('d-flex');
    });
  });
}

const setupPlaces = (type, prefix, tag, needProxy) => {
  const placesAutocomplete = places({
    container: document.querySelector(`#${prefix}_${tag}`),
    countries: ['FR'],
    aroundLatLngViaIP: true,
    type,
    appId: window.algolia_places_app_id,
    apiKey: window.algolia_places_api_key,
    clientOptions: clientOptionsWithProxy('places', needProxy),
    templates: {
      value: function(suggestion) {
        return suggestion.name;
      },
      suggestion: function(suggestion) {
        return suggestion.highlight.name + ' <span class="administrative">' + suggestion.administrative + '</span>';
      }
    },
    autocompleteOptions: {
      autoselect: true,
      autoselectOnBlur: true,
      hint: true
    }
  });

  const $lat = document.querySelector(`#${prefix}_lat`)
  const $lng = document.querySelector(`#${prefix}_lng`)
  const $county = document.querySelector(`#${prefix}_county`)
  const $postcode = document.querySelector(`#${prefix}_postcode`)
  const $administrative = document.querySelector(`#${prefix}_administrative`)

  placesAutocomplete.on('change', e => {
    $lat.value = e.suggestion.latlng.lat;
    $lng.value = e.suggestion.latlng.lng;
    $county.value = e.suggestion.county || e.suggestion.city || e.suggestion.name;
    $postcode.value = e.suggestion.postcode;
    $administrative.value = e.suggestion.administrative;
  });
}

const setupLabelsAndAccessibility = () => {

  const stepLabel = () => {
    if ($(window).width() < 768) {
      return 'Votre métier';
    } else {
      return 'Tapez le métier pour lequel vous souhaitez obtenir un diplôme';
    }
  }

    // Search labels
  $("<label class='form-control-placeholder form-control-lg-placeholder' for='search_query' id='label_search_query'>" + stepLabel() + "</label>").insertAfter("#search_query");
  $("#search_query").parent().addClass('form-label-group');
  $("<label class='form-control-placeholder form-control-lg-placeholder' for='search_geolocation_text' id='residence'>Votre ville de résidence</label>").insertAfter("#search_geolocation_text");
  $("#search_geolocation_text").parent().addClass('form-label-group');

  // accessibility
  setTimeout(function() {
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

    $('#algolia-autocomplete-listbox-0').attr('aria-label', 'liste des métiers ou diplomes');
    $('#algolia-autocomplete-listbox-0').attr('aria-selected', 'false');
  }, 200);

  $(window).on('resize', e => {
    $('#label_search_query').text(stepLabel());
  });
}

$(() => {
  if ($('.dm-search-box').length) {
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
      setupPlaces('city', 'search', 'geolocation_text', needProxy);
      setupLabelsAndAccessibility();
    });

  }
});
