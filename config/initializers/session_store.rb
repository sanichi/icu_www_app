# At the moment Apache redirects icu.ie to www.icu.ie. If it didn't, then adding:
#
#   domain: ".icu.ie"
#
# (in production only of course) would make sure sessions get shared between the two.
IcuWwwApp::Application.config.session_store :cookie_store, key: "_www_session"
