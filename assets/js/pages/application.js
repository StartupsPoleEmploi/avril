import $ from 'jquery';

(() => {

  $('input[type="tel"]').on('keyup', e => {
    const numbers = e.target.value.split("").filter(char => char.match(/[0-9]/))
    e.target.value = numbers.reduce((string, number, i) => {
      return `${string}${number}${(i % 2 && i < 9) ? ' ' : ''}`
    }, "");
  });

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

    $('a.show-hidden-meetings').on('click', e => {
      $('.meeting-card').removeClass('d-none');
      $(e.target).hide();
      e.preventDefault();
    })

    const activateSubmitButton = () => {
      if ($('select.date-select:not(:disabled)').length) {
        $('form.select-meeting').find('button[name="book"]').removeAttr('disabled');
      } else {
        $('form.select-meeting').find('button[name="book"]').attr('disabled', 'disabled');
      }
    }
    activateSubmitButton();

    $('.meeting-card').on('click', e => {
      document.getElementById('when').scrollIntoView({behavior: 'smooth', block: 'center'});
      $('.date-select').attr('disabled', true);
      $(`#${$(e.currentTarget).attr('id').replace('tab-', 'select-')}`).removeAttr('disabled');
      activateSubmitButton();
    });
  }
})();
