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
