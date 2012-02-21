# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'

require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'
require 'capybara/rspec'
require 'rspec/expectations'
require 'webmock/rspec'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # config.include ControllerHelper, :type => :controller
  # config.include RequestHelper, :type => :request

  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    # load Rails.root.join('db', 'seeds.rb')
    WebMock.disable_net_connect!(:allow_localhost => true)
    DatabaseCleaner.start
    SuperNode::Bucket.send(:redis).flushall
  end

  # [:model, :controller, :request].each do |example_type|
  #   config.before(:each, :type => example_type) do
  #     Twitter.stub(:user) do |username|
  #       mock(Twitter::User, :screen_name => username.strip)
  #     end
  #     Facebook.stub(:access_token).and_return("abc123")
  #   end
  # end

  config.after(:each) do
    WebMock.allow_net_connect!
    DatabaseCleaner.clean
  end
end