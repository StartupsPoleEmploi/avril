import $ from 'jquery';

$(() => {
  const $pagination = $('#pagination-steps');
  const $previousStep = $pagination.find('#previous-step').parent();
  const $nextStep = $pagination.find('#next-step').parent();
  const $stepsRoot = $('#steps');
  const $steps = $stepsRoot.find('[id^=step_]');

  if ($pagination.length && $stepsRoot.length) {
    const getCurrentStep = () => (parseInt($steps.filter(':not(.d-none)').attr('id').replace(/^step_/, '')) || 1);

    const setNewStep = newStep => {
      const $newStep = $stepsRoot.find(`#step_${newStep}`);
      if (!$newStep.length) return;

      $steps.addClass('d-none');
      $newStep.removeClass('d-none');

      if (newStep === 1) {
        $previousStep.addClass('disabled');
      } else {
        $previousStep.removeClass('disabled');
      }
      if (newStep === $steps.length) {
        $nextStep.addClass('disabled');
      } else {
        $nextStep.removeClass('disabled');
      }
    }

    $previousStep.on('click', e => setNewStep(getCurrentStep() - 1))
    $nextStep.on('click', e => setNewStep(getCurrentStep() + 1))
  }
});
