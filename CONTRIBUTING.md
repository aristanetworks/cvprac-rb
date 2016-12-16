# Contributing Guidelines

Please ensure all pull requests include appropriate Yard docstrings and Rspec
tests.

After checking out the repo, run `bin/setup` to install
dependencies. Then, run `rake checks` to run the tests. You can
also run `bin/console` for an interactive prompt that will allow
you to experiment.

# Environment setup

To install this gem onto your local machine, run `bundle exec rake install`. or
to setup your environment for development, run `bundle install --path
.bundle/gems`

# Releases

To release a new version, run:

`bundle exec rake checks`
`bundle exec rake bump:[major|minor|patch|pre]`
`bundle exec rake changelog`
`bundle exec rake release`

This will create a git tag, push git commits and tags and push the .gem file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/arista-eosplus/cvprac-rb This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.
