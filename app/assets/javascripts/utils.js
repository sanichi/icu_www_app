// Link_to_function is deprecated and unobstrusive javascript recommended.
$(document).on("page:change", function() {
  $("a[data-back]").on("click", function() {
    history.back();
    return false;
  });
});
