$(function() {
  $('input[type="checkbox"]').change(function() {
    // Manage the buttons
    var items = 'input[type="checkbox"][id^="item_"]';
    var submit = 'input[type="submit"]';
    if ($(this).attr('id') == 'all_items') {
      var refund_all = $(this).is(':checked');
      $(items).prop('checked', refund_all);
      $(submit).prop('disabled', !refund_all);
    } else {
      var total = $(items).size();
      var checked = $(items + ':checked').size();
      $('#all_items').prop('checked', total == checked);
      $(submit).prop('disabled', checked == 0);
    }
    // Turn off any alerts
    $('#flash_messages .alert').hide();
  });
  $(function() {
    $('#refund_form').submit(function(event) {
      // Start the spinner before submitting
      startSpinner();
    });
  });
});
