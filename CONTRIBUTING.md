# Contributing Guidelines

Please ensure all pull requests include appropriate RDoc comments and Rspec tests.

# Environment setup

`bundle install --path .bundle/gems`

# Releases

`bundle exec rake checks`
`bundle exec rake bump:[major|minor|patch|pre]`
`bundle exec rake changelog`
`bundle exec rake release`
