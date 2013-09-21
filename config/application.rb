require File.expand_path('../boot', __FILE__)
require "yaml"

APP_CONFIG = YAML.load(File.read(File.expand_path("../app_config.yml", __FILE__))).freeze

# Pick the frameworks you want:
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "sprockets/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

# General configuration.
module IcuWwwApp
  class Application < Rails::Application
    # Express preference for double quoted attributes (single quoted is HAML's default).
    Haml::Template.options[:attr_wrapper] = '"'

    # Autoload these directories.
    config.autoload_paths += %W(#{Rails.root}/lib)
    
    # Autoload nested locales for the simple backend.
    config.i18n.load_path += Dir[Rails.root.join("config", "locales", "**", "*.yml")]
  end
end
