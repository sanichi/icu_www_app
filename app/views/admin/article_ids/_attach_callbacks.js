$('#article_ids_results').on('click', 'a.article_ids_callback', function(e) {
  e.preventDefault();
  var id = $(this).data('id');
  var title = $(this).data('title');
  article_ids_callback(id, title);
});
