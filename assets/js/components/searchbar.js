import $ from 'jquery';
import typeahead from '../lib/typeahead.bundle.js';
import {singularize} from 'avril/js/utils/string';
import {debounce} from 'avril/js/utils/function';

const url = indexName => {
  if (indexName === 'profession') {
    return res => `/diplomes?metier=${res.id}-${res.slug}`
  } else {
    return res => `/diplomes/${res.id}-${res.slug}`
  }
}

const setBuilder = ({indexName, header}) => {
  return {
    name: 'certifications',
    async: true,
    display: res => res.name,
    templates: {
      header: () => `<h5 class="title is-4">${header}</h5>`,
      pending: () => `<h6 class="title is-6">Recherche des ${header} en cours ...</h6>`,
      notFound: ({query}) => `<h6 class="title is-6">Aucun ${singularize(header.toLowerCase())} trouvé pour ${query}</h6>`,
      suggestion: res => `<p><a href="${url(indexName)(res)}">${res.name}</a></p>`,
    },
    source: debounce((query, _, callback) => {
      fetch(`/search?index=${indexName}&query=${query}`)
        .then(source => source.json())
        .then(callback)
    }, 300)
  }
}

$('#search_query').typeahead({
    classNames: {
      menu: 'avril-dropdown-menu',
      hint: 'avril-hint',
      selectable: 'avril-selectable',
      suggestion: 'avril-suggestion',
      cursor: 'avril-cursor',
      empty: 'avril-empty',
    },
    minLength: 3,
    highlight: true,
    hint: true,
  }, setBuilder({
    indexName: 'profession',
    header: 'Métiers',
  }), setBuilder({
    indexName: 'certification',
    header: 'Diplômes',
  }))
.on('typeahead:active', function(e){
  $(e.target).parents('.twitter-typeahead').addClass('is-focused');
})
.on('typeahead:idle', function(e){
  $(e.target).parents('.twitter-typeahead').removeClass('is-focused');
})
.on('typeahead:select', function(e, res){
  window.location = url(res.indexName)(res);
})