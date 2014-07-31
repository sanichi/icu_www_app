# Be sure to restart your server when you modify this file.
# Using domain => all so that sessions on www.icu.ie and icu.ie are shared.
sess_opt = { key: "_www_session" }
sess_opt[:domain] = ".icu.ie" if Rails.env.production?
IcuWwwApp::Application.config.session_store :cookie_store, sess_opt
