$(function() {
  $('#charge_modal_link').click(function() {
    if ($('#charge_modal_data').text()) {
      $('#charge_modal').modal('show');
      return false;
    } else {
      startSpinner();
    }
  });
});
