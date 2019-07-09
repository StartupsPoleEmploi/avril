import $ from 'jquery';

(() => {
  $('form.resume-upload input[type="file"]').on('change', e => {
    var $form = $(e.target).parents('form');
    if (e.target.files.length) {
      $form.find('.label').text(e.target.files[0].name);
      $form.find('button[type=submit]').removeAttr('disabled');
    } else {
      $form.find('button[type=submit]').addClass('disabled');
    }
  });

  if ($('.profile-edit .edit-button').length) {
    $('.profile-edit').on('click', '.edit-button', e => {
      $(e.delegateTarget).find('[disabled]').removeAttr('disabled').addClass('disablable');
      $('.save').removeClass('d-none')
      $('.edit-button').hide();
    })

    $('.profile-edit').on('keyup', 'input', e => {
      if ($(e.target).val()) {
        $('.save').removeClass('d-none');
        $('.edit-button').hide();
      }
    });

    $('.profile-edit').on('click', '.reset', e => {
      $(e.delegateTarget).find('.disablable').attr('disabled', 'disabled').removeClass('disablable');
      $('.save').addClass('d-none');
      $('.edit-button').show();
    });

    $('.profile-edit').on('click', '.toggle-address', e => {
      var $target = $(e.target);
      if ($target.text() === '+') {
        $(e.target).text('-')
        $(e.delegateTarget).find('.address-component').removeClass('d-none');
      } else {
        $(e.target).text('+');
        $(e.delegateTarget)
          .find('.address-component')
          .filter(function(i, el){ return !$(el).find('input').val() })
          .addClass('d-none');
      }
    });

    $('form.select-meeting').on('change', e => {
      const $input = $(e.target);
      const $form = $(e.delegateTarget);
      if ($form.find(`[name="${$input.attr('name')}"]:checked`).length) {
        $form.find('button[disabled]').removeAttr('disabled');
      }
    });

  }
})();
