$('#player_ids_results').on('click', 'a.player_ids_callback', function(e) {
  e.preventDefault();
  var id = $(this).data('id');
  var name = $(this).data('name');
  player_ids_callback(id, name);
});
