require File.expand_path('../boot', __FILE__)

# Pick the frameworks you want:
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "sprockets/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# General configuration.
module IcuWwwApp
  class Application < Rails::Application
    # Express preference for double quoted attributes (single quoted is HAML's default).
    Haml::Template.options[:attr_wrapper] = '"'

    # Autoload these directories.
    config.autoload_paths += %W(#{Rails.root}/lib)

    # The following is recomended since 4.1. See also http://stackoverflow.com/questions/20361428/rails-i18n-validation-deprecation-warning.
    I18n.config.available_locales = [:en, :ga]
    I18n.config.enforce_available_locales = true

    # Autoload nested locales for the simple backend.
    config.i18n.load_path += Dir[Rails.root.join("config", "locales", "**", "*.yml")]

    # Enable locale fallbacks for I18n for all environments.
    config.i18n.fallbacks = true

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true
  end
end
