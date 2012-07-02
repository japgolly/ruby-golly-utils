# encoding: utf-8
require File.expand_path('../lib/golly-utils/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = "golly-utils"
  gem.version       = GollyUtils::VERSION
  gem.date          = Date.today.to_s
  gem.summary       = %q{Golly's Utils: Reusable Ruby utility code.}
  gem.description   = %q{This contains a bunch of shared, utility code that has no external dependencies apart from Ruby stdlib.}
  gem.authors       = ["David Barri"]
  gem.email         = ["japgolly@gmail.com"]
  gem.homepage      = "https://github.com/japgolly/golly-utils"

  #gem.add_development_dependency 'corvid'

  gem.files         = File.exists?('.git') ? `git ls-files`.split($\) : Dir['*']
  gem.require_paths = %w[lib]
  gem.test_files    = gem.files.grep(/^test\//)
end
