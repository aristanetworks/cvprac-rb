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
  config.future_release = Cvprac::VERSION
end

RuboCop::RakeTask.new
RSpec::Core::RakeTask.new(:spec) do |task|
  task.rspec_opts = ['--color', '--format', 'documentation']
end

namespace :spec do
  RSpec::Core::RakeTask.new(:unit) do |task|
    task.pattern = 'spec/unit/**/*_spec.rb'
    task.rspec_opts = ['--color', '--format', 'documentation']
  end

  RSpec::Core::RakeTask.new(:system) do |task|
    task.pattern = 'spec/system/**/*_spec.rb'
    task.rspec_opts = ['--color', '--format', 'documentation']
  end
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
task ci_spec: [:ci_prep, 'ci:setup:rspec', 'spec:unit']

task checks: %I[rubocop spec:unit yard]
task default: %I[rubocop spec:unit yard]
