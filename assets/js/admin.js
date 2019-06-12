const $filters = document.querySelector('form.filter_form');

$filters.addEventListener('paste', (event) => {
  let paste = (event.clipboardData || window.clipboardData).getData('text');
  paste = paste.trim();
});