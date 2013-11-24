source "https://rubygems.org"

gem "rails", "4.0.1"
gem "mysql2"
gem "haml-rails"
gem "sass-rails", "~> 4.0.0"
gem "uglifier", ">= 1.3.0"
gem "jquery-rails"
gem "turbolinks"
gem "cancan", "~> 1.6"
gem "redis"
gem "therubyracer", "0.12.0", :require => "v8"
gem "icu_name"
gem "icu_utils"
gem "validates_timeliness", "~> 3.0"
gem "redcarpet"

group :development do
  gem "sshkit", "1.0.0"  # until 'verbosity' bug with --dry-run is fixed
  gem "capistrano"
  gem "capistrano-rails"
  gem "capistrano-bundler"
  gem "wirble"
end

group :development, :test do
  gem "rspec-rails"
  gem "capybara"
  gem "selenium-webdriver"
  gem "factory_girl_rails", "~> 4.0"
  gem "launchy"
  gem "faker"
  gem "database_cleaner"
end
