import $ from 'jquery';

$(() => {
  const expandAccordion = ($panel, noToggle) => {
    const panelNb = $panel.attr('data-nb');
    $(`.panel.is-accordion:not([data-nb=${panelNb}])`).removeClass('is-expanded');
    noToggle ? $panel.addClass('is-expanded') : $panel.toggleClass('is-expanded');
    if ($panel.hasClass('is-expanded')) {
      window.location.hash = `#question-${panelNb}`
    }
  }

  if ($('.panel.is-accordion').length) {
    const index = parseInt(window.location.hash.replace(/^#question-/, ''));
    if (index) {
      expandAccordion($(`.panel.is-accordion[data-nb=${index}]`), true);
    }
  }

  $('.panel.is-accordion').on('click', e => {
    expandAccordion($(e.delegateTarget));
  });
});