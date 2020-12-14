import $ from 'jquery';
import typeahead from '../lib/typeahead.bundle.js';

const setBuilder = indexName => {
  return {
    name: 'certifications',
    async: true,
    display: res => res.label,
    source: (query, _, callback) => {
      fetch(`/search?index=${indexName}&query=${query}`)
        .then(source => source.json())
        .then(callback)
  }
}

$('#search_query').typeahead({
    minLength: 3,
    highlight: true
  }, setBuilder('certification'), setBuilder('profession'))

// import autoComplete from "@tarekraafat/autocomplete.js/dist/js/autoComplete";

// console.log(new autoComplete({
//   name: 'searchbar',
//   data: {
//     cache: false,
//     key: ['label'],
//     src: async () => {
//       const query = document.querySelector("#search_query").value;
//       const source = await fetch(`/search?index=certification&query=${query}`);
//       const data = await source.json();
//       return data;
//     }
//   },
//   threshold: 3,
//   debounce: 300,
//   selector: "#search_query",
//   resultsList: {
//     render: true,
//     container: source => {
//       console.log(source)
//         source.setAttribute("id", "food_list");
//     },
//     destination: "#search_results",
//     position: "afterend",
//     element: "ul"
//   },
//   highlight: true,
//   resultItem: {
//     content: (data, element) => {
//       console.log(data)
//       // Prepare Value's Key
//       const key = Object.keys(data).find((key) => data[key] === element.innerText);
//       // Modify Results Item
//       element.style = "display: flex; justify-content: space-between;";
//       element.innerHTML = `<span style="text-overflow: ellipsis; white-space: nowrap; overflow: hidden;">
//         ${element.innerHTML}</span>
//         <span style="display: flex; align-items: center; font-size: 13px; font-weight: 100; text-transform: uppercase; color: rgba(0,0,0,.2);">
//       ${key}</span>`;
//     }
//   },
// }))

// const searchbar = new autoComplete({
//   data: {                              // Data src [Array, Function, Async] | (REQUIRED)
//     src: async () => {
//       // User search query
//       const query = document.querySelector("#search_query").value;
//       console.log(query)
//       // Fetch External Data Source
//       const source = await fetch(`/search?query=${query}&index=certification`);
//       // Format data into JSON
//       const data = await source.json();
//       console.log(data)
//       // Return Fetched data
//       return data;
//     },
//     key: ["title"],
//     cache: false
//   },
//   // query: {                             // Query Interceptor               | (Optional)
//   //       manipulate: (query) => {
//   //         return query.replace("pizza", "burger");
//   //       }
//   // },
//   // sort: (a, b) => {                    // Sort rendered results ascendingly | (Optional)
//   //     if (a.match < b.match) return -1;
//   //     if (a.match > b.match) return 1;
//   //     return 0;
//   // },
//   placeHolder: "Food & Drinks...",     // Place Holder text                 | (Optional)
//   selector: "#search_query",           // Input field selector              | (Optional)
//   observer: true,                      // Input field observer | (Optional)
//   threshold: 3,                        // Min. Chars length to start Engine | (Optional)
//   debounce: 300,                       // Post duration for engine to start | (Optional)
//   searchEngine: "strict",              // Search Engine type/mode           | (Optional)
//   resultsList: {                       // Rendered results list object      | (Optional)
//       render: true,
//       container: source => {
//           source.setAttribute("id", "food_list");
//       },
//       destination: "#search_query",
//       position: "afterend",
//       element: "ul"
//   },
//   maxResults: 5,                         // Max. number of rendered results | (Optional)
//   highlight: true,                       // Highlight matching results      | (Optional)
//   resultItem: {                          // Rendered result item            | (Optional)
//       content: (data, source) => {
//           source.innerHTML = data.match;
//       },
//       element: "li"
//   },
//   noResults: (dataFeedback, generateList) => {
//       // Generate autoComplete List
//       generateList(autoCompleteJS, dataFeedback, dataFeedback.results);
//       // No Results List Item
//       const result = document.createElement("li");
//       result.setAttribute("class", "no_result");
//       result.setAttribute("tabindex", "1");
//       result.innerHTML = `<span style="display: flex; align-items: center; font-weight: 100; color: rgba(0,0,0,.2);">Found No Results for "${dataFeedback.query}"</span>`;
//       document.querySelector(`#${autoCompleteJS.resultsList.idName}`).appendChild(result);
//   },
//   // onSelection: feedback => {             // Action script onSelection event | (Optional)
//   //     console.log(feedback.selection.value.image_url);
//   // }
// });

// // const ipNumber = iPaddress => {
//   const ip = iPaddress.match(/^(\d+)\.(\d+)\.(\d+)\.(\d+)$/);
//   if(ip) {
//     return (+ip[1]<<24) + (+ip[2]<<16) + (+ip[3]<<8) + (+ip[4]);
//   }
// }

// const ipMask = maskSize => {
//   return -1<<(32-maskSize);
// }

// const isInSubnet = (ip, subnetIp, subnetMask) => {
//   return (ipNumber(ip) & ipMask(subnetMask)) === ipNumber(subnetIp);
// }

// const clientOptionsWithProxy = (key, needProxy) => {
//   return needProxy ? {
//     hosts: [`algolia-${key}.beta.pole-emploi.fr`]
//   } : null;
// }

// const indexName = baseName => `${window.algolia_indice_prefix || ''}${baseName}`

// const setupSearchBar = needProxy => {
//   const client = algoliasearch(
//     window.algolia_app_id,
//     window.algolia_search_api_key,
//     clientOptionsWithProxy(window.algolia_app_id, needProxy)
//   );

//   const professionToPath = suggestion => `/diplomes?metier=${suggestion.id}-${suggestion.slug}`
//   const certificationToPath = suggestion => `/diplomes/${suggestion.id}-${suggestion.slug}`

//   autocomplete('#search_query', {
//     ariaLabel: 'Cherchez un métier ou un diplôme',
//     autoselect: true,
//     autoselectOnBlur: true,
//     cssClasses: {
//       prefix: 'avril'
//     },
//     minLength: 3,
//   }, [{
//     source: autocomplete.sources.hits(client.initIndex(indexName('profession')), {
//       hitsPerPage: 5,
//       queryType: 'prefixAll',
//     }),
//     displayKey: suggestion => suggestion.label,
//     debounce: 500,
//     templates: {
//       header: '<h5 class="title">Métiers</div>',
//       suggestion: suggestion => `<a href="${professionToPath(suggestion)}">${suggestion._highlightResult.label.value}</a>`,
//     }
//   }, {
//     source: autocomplete.sources.hits(client.initIndex(indexName('certification')), {
//       hitsPerPage: 3,
//       queryType: 'prefixAll',
//       facetFilters: 'is_active:true',
//     }),
//     debounce: 500,
//     displayKey: suggestion => {
//       const acronym = suggestion.acronym;
//       const label = suggestion.label;
//       return acronym ? `${acronym} ${label}` : label;
//     },
//     templates: {
//       header: '<h5 class="title">Dîplomes</div>',
//       suggestion: suggestion => {
//         const acronym = suggestion._highlightResult.acronym && suggestion._highlightResult.acronym.value;
//         const label = suggestion._highlightResult.label.value;
//         const value = acronym ? `${acronym} ${label}` : label;
//         return `<a href="${certificationToPath(suggestion)}">${value}</a>`;
//       }
//     }
//   }])
//   .on('ready', e => {
//     setupLabelsAndAccessibility();
//   })
//   .on('autocomplete:selected', (event, suggestion, datasetIndex) => {
//     window.location.href = datasetIndex === 1 ? professionToPath(suggestion) : certificationToPath(suggestion);
//   });
// }

// const setupLabelsAndAccessibility = () => {
//   $('#certification_finder label.label').insertAfter($('#certification_finder input.avril-input[type=search]'));
//   // Ajout d'un aria pour aider à la compréhesion de l'utilité
//   $('#algolia-places-listbox-0').attr('aria-labelledby', "residence");
//   $('#algolia-places-listbox-0').attr('aria-selected', "false");
//   // Ajout d'un aria atomic pour les aria assertive. A quoi çà sert ? Je ne sais pas.
//   $("[aria-live='assertive']").attr('aria-atomic', 'true');
//   // Ajout d'un aide à la compréhesion de qui controle quoi
//   $('#search_geolocation_text').attr('aria-controls', 'algolia-places-listbox-0');

//   $('#search_query').attr('aria-controls', 'algolia-autocomplete-listbox-0');
//   $('#search_query').attr('aria-activedescendant', '');
//   $('#search_query').attr('aria-readonly', 'true');

//   $('#algolia-autocomplete-listbox-0').attr('aria-label', 'liste des métiers ou diplômes');
//   $('#algolia-autocomplete-listbox-0').attr('aria-selected', 'false');
// }

// $(() => {
//   if ($('#certification_finder').length) {
//     let needProxy = false;
//     $.get('https://api.ipify.org')
//     .done(ip => {
//       needProxy = isInSubnet(ip, '185.215.64.0', '22');
//     })
//     .fail(() => {
//       needProxy = true;
//     })
//     .always(() => {
//       console.log('Proxy set ? ', needProxy);
//       setupSearchBar(needProxy);
//     });

//   }
// });
