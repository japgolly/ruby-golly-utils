To install locally:
    gem build golly-utils.gemspec
    gem install golly-utils-x.x.x.gem

To perform a release:
* Update `CHANGELOG.md`
* `bundle exec rake test`
* Ensure no uncommitted changes.
* `gem build golly-utils.gemspec`
* `gem push golly-utils-x.x.x.gem`
* `git tag -s x.x.x`
* Update `version.rb`
* Commit

