# Contributing Guidelines

Please ensure all pull requests include appropriate Yard docstrings and Rspec
tests.

After checking out the repo, run `bin/setup` to install
dependencies and setup git hooks. Then, run `bundle exec rake
checks` to run the tests. You can also run `bin/console` for an
interactive prompt that will allow you to experiment.

# Environment setup

To install this gem onto your local machine, run `bundle exec rake install`. or
to setup your environment for development, run `bundle install --path
.bundle/gems`

# Releases

To release a new version, run:

`rvm use ruby-2.3.1`
`bundle install --path .bundle/gems`
`bundle exec rake checks`
`bundle exec rake bump:[major|minor|patch|pre]`
`bundle exec rake changelog`
`git push --set-upstream origin release-1.0.0`
Create a PR against develop
Wait for CI to complete
`git checkout develop`
`git merge --no-ff release-1.0.0`
`git push origin develop`
Create a PR against master
Wait for CI to complete
`git checkout master`
`git merge --no-ff develop`
`git push origin master`
`bundle exec rake release`

**TODO** Update version in develop

This will create a git tag, push git commits and tags and push the .gem file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on
[GitHub](https://github.com/arista-aristanetworks/cvprac-rb).

This project is intended to be a safe, welcoming space for collaboration, and
contributors are expected to adhere to the [Contributor
Covenant](http://contributor-covenant.org) code of conduct.
