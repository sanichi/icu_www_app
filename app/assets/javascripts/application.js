// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require bootstrap.min

// Auto-submit on change.
$(function() {
  $('form .auto_submit').change(function() {
    $(this).parents('form').submit();
  });
});

// For obscuring email addresses. Shpx gur fcnzzref.
function liame() {
  var a = new Array();
  for (var i=0; i<arguments.length; i++)
  {
    a.push(elgnam(arguments[i]));
  }
  document.write(a.reverse().join('.'));
}
function elgnam(str)
{
  return str.replace(/[a-zA-Z]/g, function(c)
  {
    return String.fromCharCode((c<='Z'?90:122)>=(c=c.charCodeAt(0)+13)?c:c-26);
  });
}
