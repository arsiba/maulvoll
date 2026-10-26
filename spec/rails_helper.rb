require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
abort("Production environment!") if Rails.env.production?
require "rspec/rails"
ActiveRecord::Migration.maintain_test_schema!
RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.include FactoryBot::Syntax::Methods
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
  config.before { Rack::Attack.cache.store.clear }
  config.after { Current.reset }
end
