source ENV['GEM_SOURCE'] || 'https://rubygems.org'

gemfile

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mygem/version'

group :development, :test do
  gem 'bundler'
  gem 'mygem', Mygem::VERSION, path: '.'
  gem 'pry'
  gem 'rake'
  gem 'rubocop', '>= 0.43'
  gem 'yard'
end

group :development do
  gem 'bump'
  gem 'github_changelog_generator'
end

group :test do
  # gem "codeclimate-test-reporter", "~>0.4"
  # gem "coveralls", "~>0.8", require: false
  gem 'ci_reporter_rspec', require: false
  gem 'rspec', '< 4'
  gem 'simplecov', '~>0.10', require: false
  gem 'simplecov-json',          require: false
  gem 'simplecov-rcov',          require: false
  # gem "webmock"
end
