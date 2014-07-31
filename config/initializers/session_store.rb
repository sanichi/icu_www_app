# Be sure to restart your server when you modify this file.
# Using domain => all so that sessions on www.icu.ie and icu.ie are shared.
IcuWwwApp::Application.config.session_store :cookie_store, key: "_www_session", domain: :all
