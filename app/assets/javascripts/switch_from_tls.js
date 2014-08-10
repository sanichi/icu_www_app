/*
 * Convert links to HTTP (instead of HTTPS), assuming the hrefs are full paths beginning with "/".
 * Helps to prevent a user getting stuck on HTTPS. Example: they go to the sign-in page (which
 * is HTTPs) but then instead of signing in (which would have redirected them to HTTP) they click
 * some link. Without this file (or some redirecting in Apache) they would still be on HTTPS.
 * This file is only for production and only for those pages that require TLS. Typical usage:
 *
 * - if Rails.env.production?
 *   - content_for :includes do
 *     = javascript_include_tag "switch_from_tls.js"
 */
$(function() {
  $('a').click(function() {
    var href = $(this).attr('href');
    if (!href || href.match(/^http/) || !href.match(/^\//) || href.match(/^\/sign_(in|up)$/)) {
      return true;
    } else {
      document.location.href = "http://www.icu.ie" + href;
      return false;
    }
  });
});
