// Link_to_function is deprecated and unobstrusive javascript recommended.
$(document).ready(function() {
  $("a[data-back]").on("click", function() {
    history.back();
    return false;
  });
});
