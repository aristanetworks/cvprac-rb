require 'simplecov'
require 'simplecov-rcov'
require 'webmock/rspec'

SimpleCov.formatters = [
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::RcovFormatter
]
SimpleCov.start do
  add_filter '/spec/'
  add_filter '/.bundle/'
end

# Must come after simplecov
require 'cvprac'

# Include libs in the spec/support dir
dir = File.expand_path(File.dirname(__FILE__))
print "Support dir: #{dir}\n"
Dir["#{dir}/support/**/*.rb"].sort.each { |f| require f }

include FixtureHelpers

WebMock.disable_net_connect!(net_http_connect_on_start: true)

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
    mocks.syntax = :expect
  end

  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  config.warnings = true

  # config.default_formatter = 'doc' if config.files_to_run.one?
  config.default_formatter = 'fuubar' if config.files_to_run.one?
end
