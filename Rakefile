# Rakefile
require 'bump/tasks'
require 'bundler/gem_tasks'
require 'github_changelog_generator/task'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'cvprac/version'

GitHubChangelogGenerator::RakeTask.new :changelog do |config|
  config.future_release = '0.2.0'
end

RuboCop::RakeTask.new
RSpec::Core::RakeTask.new(:spec) do |task|
  task.rspec_opts = ['--color', '--format', 'documentation']
end

task checks: [:rubocop, :spec]
task default: [:rubocop, :spec]
