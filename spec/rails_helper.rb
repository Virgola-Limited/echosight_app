# frozen_string_literal: true

# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
require 'capybara/rspec'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
# Prevent database truncation if the environment is production
abort('The Rails environment is running in production mode!') if Rails.env.production?
require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!
require 'sidekiq/testing'

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
Rails.root.glob('spec/support/**/*.rb').sort.each { |f| require f }

# Checks for pending migrations and applies them before tests are run.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end
RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.include ActiveSupport::Testing::TimeHelpers
  config.include ActionMailer::TestHelper
  config.include EmailHelpers

  config.fixture_paths = [
    Rails.root.join('spec/fixtures')
  ]

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # You can uncomment this line to turn off ActiveRecord support entirely.
  # config.use_active_record = false

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, type: :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://rspec.info/features/6-0/rspec-rails
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")

  #######################
  # Capybara / Feature test setup

  Capybara.register_driver :selenium_chrome_headless do |app|
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument('--headless')
    options.add_argument('--disable-gpu')
    options.add_argument('--window-size=1280,1024') #
    Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
  end
  if ENV['HEADLESS']
    driver = :selenium_chrome_headless
  else
    driver = :selenium_chrome
  end
  Capybara.javascript_driver = driver
  Capybara.default_driver = driver
  # Capybara.default_driver = :selenium

  config.include Capybara::DSL, type: :feature
  config.include Devise::Test::IntegrationHelpers, type: :feature
  config.include AuthenticationHelper, type: :feature
  config.before(:each, type: :feature) do
    ActionMailer::Base.deliveries.clear
    WebMock.allow_net_connect!
  end

  config.before(:each) do
    allow(CreateStripeCustomerWorkerJob).to receive(:perform_async)
  end

  config.after(:each, type: :feature) do |example|
    # if page.driver.browser.respond_to?(:logs)
      # check_for_errors(example)
    # end
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  config.around(:each, type: :feature) do |example|
    VCR.turned_off { example.run }
  end


  #######################

end

def check_for_errors(example)
  return if example.metadata[:ignore_errors]

  errors = page.driver.browser.logs.get(:browser)
  filtered_errors = errors.reject do |e|
    ignorable_errors.any? { |ignore| e.message.include?(ignore) }
  end
  error_messages = filtered_errors.map(&:message).join("\n")
  expect(filtered_errors).to(
    be_empty, "JavaScript errors found on:\n
       #{page.current_url}\n\n

       Failing example: #{example.full_description}\n\n
       File path: #{example.file_path}\n\n

       Error message:\n
       #{error_messages}\n\n
       "
  )
  # Added this as a test was throwing a 500 error but not failing.
  expect(page).not_to have_selector('.exception')
end

def ignorable_errors
  [
  ]
end
