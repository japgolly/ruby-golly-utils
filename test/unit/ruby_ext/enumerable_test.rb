# encoding: utf-8
require_relative '../../bootstrap/unit'
require 'golly-utils/ruby_ext/enumerable'

class EnumerableTest < MiniTest::Unit::TestCase

  def test_frequency_map
    x= [1, 4, 'a', 4, :b, :b, :b].frequency_map
    assert_equal({1=>1, 4=>2, 'a'=>1, b:3}, x)
  end

end
