function ready_to_submit_new_item(boolean) {
  if (boolean) {
    $('#new_item input[type="submit"]').show();
    $('.select-player-button').removeClass('btn-info').addClass('btn-default');
  } else {
    $('#new_item input[type="submit"]').hide();
  }
}

$(function() {
  if ($('#item_player_id').size() > 0) {
    var got_player = $('#item_player_id').val() ? true : false;
    if (!got_player && $('#item_player_data').size() > 0) got_player = $('#item_player_data').val() ? true : false;
    ready_to_submit_new_item(got_player);
  }
});
