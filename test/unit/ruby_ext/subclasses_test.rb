# encoding: utf-8
require_relative '../../bootstrap/unit'
require 'golly-utils/ruby_ext/subclasses'

class SubclassesTest < MiniTest::Unit::TestCase
  class A; end
  class B < A; end
  class C < A; end
  class B1 < B; end
  class B2 < B; end

  def assert_arrays(exp,act)
    v= [exp,act].map{|a| a.sort_by(&:to_s) }
    assert_equal *v
  end

  def test_all_subclasses
    assert_arrays [B,C,B1,B2], A.subclasses(true)
  end

  def test_leaf_nodes_only
    assert_arrays [C,B1,B2], A.subclasses
  end
end
