# frozen_string_literal: true

source 'https://rubygems.org'

ruby '3.2.2'

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem 'rails', '~> 7.1.1'

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem 'sprockets-rails'

# Use postgresql as the database for Active Record
gem 'pg', '~> 1.1'

# Use the Puma web server [https://github.com/puma/puma]
gem 'puma', '>= 5.0'

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem 'turbo-rails'

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem 'stimulus-rails'

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem 'jbuilder'

# Use Redis adapter to run Action Cable in production
gem 'redis', '>= 4.0.1'

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[windows jruby]

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false

gem 'activeadmin'
gem 'apexcharts'
gem "aws-sdk-s3", "~> 1.14"
gem 'devise', '~> 4.9'
gem 'devise_invitable'
gem 'exception_notification'
gem 'fastimage'
gem 'omniauth-rails_csrf_protection'
gem 'omniauth-twitter2'
gem 'paper_trail'
gem 'premailer-rails'
# Needed for activeadmin as we dont use webpacker #https://github.com/activeadmin/activeadmin/issues/6636
gem 'sassc'
gem 'shrine'
gem 'sidekiq'
gem 'sidekiq-cron'
gem 'slack-notifier'
gem 'stripe'
gem 'view_component'
gem 'vite_rails'
gem 'whenever', require: false
gem 'x', '~> 0.14.1'

group :development, :test do
  gem 'bullet'
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem 'byebug', '~> 11.1'
  gem 'capybara'
  gem 'debug', platforms: %i[mri windows]
  gem 'dotenv'
  gem 'factory_bot_rails', require: false
  gem 'faker'
  gem 'htmlbeautifier'
  gem 'rspec-rails', '~> 6.1.0'
  gem 'webdrivers', require: false
  gem 'vcr'
  gem 'webmock'
end

group :development do
  gem 'annotate'
  gem 'better_errors'
  gem 'binding_of_caller'
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem 'guard-rspec', require: false
  gem 'rack-mini-profiler'
  gem 'rubocop'
  gem 'web-console'


  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
end
