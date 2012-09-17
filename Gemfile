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
  gem 'rb-inotify', '>= 0.8.8', require: false
end
