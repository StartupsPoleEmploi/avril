import $ from 'jquery';

$(() => {
  $('form.toggler').on('change', e => {
    const $form = $(e.delegateTarget);
    const $hiddenInput = $form.find('input[type=hidden][name=levels]')
    const $allInput = $form.find('input#all_levels');
    const $valueInputs = $form.find('input[id^=level_]');
    const $checkedValueInputs = $valueInputs.filter(':checked');

    if ($(e.target).attr('id') == $allInput.attr('id') || $valueInputs.length == $checkedValueInputs.length) {
      $valueInputs.prop('checked', false);
      $allInput.prop('checked', true);
    } else {
      $allInput.prop('checked', !$checkedValueInputs.length);
    }

    const values = $valueInputs.filter(':checked').toArray().map(el => $(el).val());
    if (values.length) {
      $hiddenInput.removeAttr('disabled');
      $hiddenInput.val(values.join(","));
    } else {
      $hiddenInput.attr('disabled', true);
    }
    $form.submit();
  });
});