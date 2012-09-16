source :rubygems
gemspec

# Load Corvid dependencies
eval File.read(File.expand_path '../.corvid/Gemfile', __FILE__)

# Parser for Markdown documentation
group :doc do
  gem 'rdiscount', platforms: :mri
  gem 'kramdown', platforms: :jruby
end

group :test do
  gem 'guard', '>= 1.3.2', require: false
  gem 'listen', '~> 0.4.7', require: false
end
