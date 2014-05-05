source "https://rubygems.org"
source 'https://code.stripe.com'

gem "rails", "4.1.0"
gem "mysql2"
gem "haml-rails"
gem "sass-rails", "~> 4.0.3"
gem "uglifier", ">= 1.3.0"
gem "jquery-rails"
gem "cancan", "~> 1.6"
gem "redis"
gem "therubyracer", platforms: :ruby
gem "icu_name"
gem "icu_utils"
gem "validates_timeliness", github: "razum2um/validates_timeliness", ref: "b195081f6aeead619430ad38b0f0dfe4d4981252" # See https://github.com/adzap/validates_timeliness/pull/114.
#gem "validates_timeliness", "~> 3.0"
gem "redcarpet"
gem "stripe"
gem "mailgun-ruby", require: "mailgun"
gem "paperclip", "~> 4.1"

group :development do
  gem "capistrano"
  gem "capistrano-rails"
  gem "capistrano-bundler"
  gem "wirble"
end

group :development, :test do
  gem "rspec-rails"
  gem "capybara"
  gem "selenium-webdriver"
  gem "factory_girl_rails", "~> 4.0", require: false
  gem "launchy"
  gem "faker"
  gem "database_cleaner"
end
