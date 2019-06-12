import $ from 'jquery';

$(() => {
  const $pagination = $('#pagination-steps');
  const $previous_step = $pagination.find('#previous-step').parent();
  const $next_step = $pagination.find('#next-step').parent();
  const $steps_root = $('#steps');
  const $steps = $steps_root.find('[id^=step_]');

  if ($pagination.length && $steps_root.length) {
    const getCurrentStep = () => (parseInt($steps.filter(':not(.d-none)').attr('id').replace(/^step_/, '')) || 1);

    const setNewStep = newStep => {
      const $newStep = $steps_root.find(`#step_${newStep}`);
      if (!$newStep.length) return;

      $steps.addClass('d-none');
      $newStep.removeClass('d-none');

      if (newStep === 1) {
        $previous_step.addClass('disabled');
      } else {
        $previous_step.removeClass('disabled');
      }
      if (newStep === $steps.length) {
        $next_step.addClass('disabled');
      } else {
        $next_step.removeClass('disabled');
      }
    }

    $previous_step.on('click', e => setNewStep(getCurrentStep() - 1))
    $next_step.on('click', e => setNewStep(getCurrentStep() + 1))
  }
});
