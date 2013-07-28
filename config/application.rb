require File.expand_path('../boot', __FILE__)
require "yaml"

APP_CONFIG = YAML.load(File.read(File.expand_path("../app_config.yml", __FILE__)))

# Pick the frameworks you want:
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "sprockets/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

module IcuWwwApp
  class Application < Rails::Application
    # Express preference for double quoted attributes (single quoted is HAML's default).
    Haml::Template.options[:attr_wrapper] = '"'
  end
end
