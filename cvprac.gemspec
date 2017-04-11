# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cvprac/version'

# rubocop:disable Style/UnneededPercentQ
Gem::Specification.new do |spec|
  spec.name          = 'cvprac'
  spec.version       = Cvprac::VERSION
  spec.authors       = ['Arista Networks']
  spec.email         = ['eosplus-dev@arista.com']
  spec.summary       = %q(Arista REST API Client for CloudVision Portal)
  spec.description   = %q(Arista REST API Client for CloudVision Portal)
  spec.homepage      = 'https://github.com/arista-aristanetworks/cvprac-rb'
  spec.license       = 'BSD-3-Clause'

  # NOTE: This may cause issues on Jenkins in detached head
  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(bin|test|spec|features)/})
  end
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.metadata['yard.run'] = 'yri' # use "yard" to build full HTML docs.

  # spec.add_runtime_dependency 'inifile', '~> 0'
  spec.add_runtime_dependency 'http-cookie'
  spec.add_runtime_dependency 'require_all'

  spec.add_development_dependency 'bump'
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'ci_reporter'
  spec.add_development_dependency 'ci_reporter_rspec'
  spec.add_development_dependency 'fuubar'
  spec.add_development_dependency 'github_changelog_generator'
  spec.add_development_dependency 'guard'
  spec.add_development_dependency 'guard-rspec'
  spec.add_development_dependency 'json'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'pry-remote'
  spec.add_development_dependency 'pry-nav'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rb-readline'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rspec-core'
  spec.add_development_dependency 'rspec-expectations'
  spec.add_development_dependency 'rspec-mocks'
  spec.add_development_dependency 'rspec-nc'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'simplecov-rcov'
  spec.add_development_dependency 'webmock'
  spec.add_development_dependency 'yard'

  spec.required_ruby_version = '>= 1.9.3'
end
