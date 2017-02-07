# Rakefile
require 'bump/tasks'
require 'bundler/gem_tasks'
require 'ci/reporter/rake/rspec'
require 'github_changelog_generator/task'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'yard'

$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'cvprac/version'

GitHubChangelogGenerator::RakeTask.new :changelog do |config|
  config.future_release = '0.2.0'
end

RuboCop::RakeTask.new
RSpec::Core::RakeTask.new(:spec) do |task|
  task.rspec_opts = ['--color', '--format', 'documentation']
end

YARD::Rake::YardocTask.new do |t|
  t.files = ['lib/**/*.rb']
end

desc 'Prep CI RSpec tests'
task :ci_prep do
  require 'rubygems'
  begin
    gem 'ci_reporter'
    require 'ci/reporter/rake/rspec'
    ENV['CI_REPORTS'] = 'results'
  rescue LoadError
    puts 'Missing ci_reporter gem. You must have the ci_reporter gem ' \
         'installed to run the CI spec tests'
  end
end

desc 'Run the CI RSpec tests'
task ci_spec: [:ci_prep, 'ci:setup:rspec', :spec]

task checks: [:rubocop, :spec, :yard]
task default: [:rubocop, :spec, :yard]
