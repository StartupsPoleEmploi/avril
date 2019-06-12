import $ from 'jquery';

$(() => {
  const $levelSelector = $('#level-selector');
  if ($levelSelector.length) {

    $levelSelector.on('loaded.bs.select', e => {
      $(e.target).parent().find('.dropdown-menu').append(`
        <div class="bs-actionsbox">
          <div class="btn-group btn-group-sm btn-block">
            <button type="button" class="btn btn-primary">Filtrer</button>
          </div>
        </div>
      `);
    });

    $levelSelector.on('hide.bs.select', (e, clickedIndex, isSelected, previousValue) => {
      const arrayOptions = Array.from(e.target.selectedOptions).map(o => o.value);
      let params = new URLSearchParams(window.location.search);
      params.set('levels', arrayOptions);
      window.location.search = params.toString();
    });

    $levelSelector.selectpicker({
      countSelectedText: function(number, total) {
        if(number === total) {
          return 'Tous les niveaux'
        } else {
          return number + ' niveaux sélectionnés'
        }
      },
      actionsBox: true,
      title: "Sélectionnez un niveau",
      dropupAuto: false,
      style: 'btn-link px-0',
      selectedTextFormat: 'count > 1',
      selectAllText: 'Tout sélectionner',
      deselectAllText: 'Tout désélectionner'
    });

    let params = new URLSearchParams(window.location.search);
    let defaultValue = (params.get('levels') || "1,2,3,4,5").split(',');
    $levelSelector.selectpicker('val', defaultValue);
  }
})