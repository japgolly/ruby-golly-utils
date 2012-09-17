# encoding: utf-8
require File.expand_path('../lib/golly-utils/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name        = "golly-utils"
  gem.version     = GollyUtils::VERSION.dup
  gem.date        = Time.new.strftime '%Y-%m-%d'
  gem.summary     = %q{Golly's Utils: Reusable Ruby utility code.}
  gem.description = %q{This contains a bunch of shared, utility code that has no external dependencies apart from Ruby stdlib.}
  gem.authors     = ["David Barri"]
  gem.email       = ["japgolly@gmail.com"]
  gem.homepage    = "https://github.com/japgolly/golly-utils"

  gem.files         = File.exists?('.git') ? `git ls-files`.split($\) : \
                      Dir['**/*'].reject{|f| !File.file? f or %r!^(?:target|resources/latest)/! === f}.sort
  gem.test_files    = gem.files.grep(/^test\//)
  gem.require_paths = %w[lib]
  gem.bindir        = 'bin'
  gem.executables   = %w[]

  gem.add_development_dependency 'corvid'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'minitest'
  gem.add_development_dependency 'rspec'
end

