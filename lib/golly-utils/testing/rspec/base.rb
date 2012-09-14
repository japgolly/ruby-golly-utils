require 'golly-utils/testing/helpers_base'

module GollyUtils::Testing::RSpecMatchers
end

RSpec::configure do |config|
  config.include GollyUtils::Testing::Helpers
  config.include GollyUtils::Testing::RSpecMatchers
end
