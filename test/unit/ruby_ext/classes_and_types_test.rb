# encoding: utf-8
require_relative '../../bootstrap/unit'
require 'golly-utils/ruby_ext/classes_and_types'

class ClassesAndTypesTest < MiniTest::Unit::TestCase
  class A; end
  class B < A; end
  class C < A; end
  class B1 < B; end
  class B2 < B; end

  def assert_arrays(exp,act)
    v= [exp,act].map{|a| a.sort_by(&:to_s) }
    assert_equal *v
  end

  def test_subclasses_all
    assert_arrays [B,C,B1,B2], A.subclasses(true)
  end

  def test_subclasses_leaf_nodes_only
    assert_arrays [C,B1,B2], A.subclasses
  end

  def test_superclasses_on_instance
    assert_equal [B1,B,A,Object,BasicObject], B1.new.superclasses
  end

  def test_superclasses_on_class
    assert_equal [B1,B,A,Object,BasicObject], B1.superclasses
  end

  def test_superclasses_on_ruby_internals
    assert_equal [NilClass,Object,BasicObject], nil.superclasses
    assert_equal [TrueClass,Object,BasicObject], true.superclasses
  end

  class BO < BasicObject; end
  def test_superclasses_on_basic_object_subclass
    assert_equal [BO,BasicObject], BO.superclasses
    #assert_equal [BO,BasicObject], BO.new.superclasses
  end
end
