# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mygem/version'

Gem::Specification.new do |spec|
  spec.name          = 'mygem'
  spec.version       = Mygem::VERSION
  spec.authors       = ['Arista Networks']
  spec.email         = ['eosplus-dev@arista.com']
  spec.description   = 'Arista REPLACEME Ruby Library'
  spec.summary       = 'This Gem library provides a Ruby interface '\
                       'to the Arista REPLACEME'
  spec.homepage      = 'https://github.com/arista-eosplus/REPLACEME'
  spec.license       = 'BSD-3-Clause'

  # NOTE: This may cause issues on Jenkins in detached head
  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.metadata['yard.run'] = 'yri' # use "yard" to build full HTML docs.

  # spec.add_runtime_dependency 'inifile', '~> 0'

  # spec.add_development_dependency 'rake', '~> 10.1', '>= 10.1.0'
  spec.add_development_dependency 'bundler', '~> 0'
  spec.add_development_dependency 'yard', '~> 0'
  spec.add_development_dependency 'rake', '~> 0'
  spec.add_development_dependency 'rspec', '~> 0'
  spec.add_development_dependency 'rspec-mocks', '~> 0'
  spec.add_development_dependency 'simplecov', '~> 0'
  spec.add_development_dependency 'pry', '~> 0'
  spec.add_development_dependency 'github_changelog_generator', '~> 0'

  spec.required_ruby_version = '>= 1.9.3'
end
