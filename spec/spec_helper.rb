# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'
require 'factory_girl_rails'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

Capybara.configure do |config|
  config.default_wait_time = 15 # be patient with Ajax wait times (includes waiting for Stripe)
end

RSpec.configure do |config|
  config.mock_with :rspec
  config.include FactoryGirl::Syntax::Methods

  # To be able to use selenium tests we use database_cleaner with truncation
  # strategy for all tests (slower but more reliable). See Railscasts 257.
  config.use_transactional_fixtures = false
  unless config.use_transactional_fixtures
    config.before(:suite) do
      DatabaseCleaner.strategy = :truncation
    end
    config.after(:each) do
      DatabaseCleaner.clean
    end
  end

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Set to "random" to run specs in random order to surface order dependencies.
  # If you find an order dependency and want to debug it, you can fix the order
  # by providing the seed, which is printed after each run: --seed 1234
  config.order = "default"
end

# Create and login a user with a given role or roles.
def login(user_or_roles, options={})
  user, roles = user_or_roles.instance_of?(User) ? [user_or_roles, nil] : [nil, user_or_roles]
  user ||= create(:user, roles: roles)
  visit sign_out_path
  fill_in I18n.t("email"), with: options[:email] || user.email
  fill_in I18n.t("user.password"), with: options[:password] || "password"
  click_button I18n.t("session.sign_in")
  user
end

# Logout the current user.
def logout
  visit sign_out_path
end

# Confirm a popup confirmation dialog.
def confirm_dialog(delay=0.2)
  sleep(delay)
  page.driver.browser.switch_to.alert.accept
  sleep(delay)
end
