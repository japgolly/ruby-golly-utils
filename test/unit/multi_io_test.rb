# encoding: utf-8
require_relative '../bootstrap/unit'
require 'golly-utils/multi_io'
require 'stringio'

class MultiIOTest < MiniTest::Unit::TestCase

  def test_writing
    a= StringIO.new
    b= StringIO.new
    a.write 'a_'
    m= MultiIO.new(a,b)
    m.write 'hehe'
    [a,b].each &:rewind
    assert_equal 'a_hehe', a.read
    assert_equal 'hehe', b.read
  end
end
