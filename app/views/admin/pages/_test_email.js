function showMessage(message, error) {
  $('#message_text').text(message);
  if (error) {
    $('#message_alert').removeClass('alert-success').addClass('alert-danger');
  } else {
    $('#message_alert').removeClass('alert-danger').addClass('alert-success');
  }
  var el = $('#message_container');
  if (el.is(':visible')) {
    el.fadeOut(100).fadeIn(100);
  } else {
    el.show();
  }
}
