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

  #---------------------------------------------------------------------------------------------------------------------

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

  #---------------------------------------------------------------------------------------------------------------------

  def test_validate_type_passes_when_exact_match
    B.new.validate_type! B
    B.new.validate_type! A
  end

  def test_validate_type_passes_with_name
    B.new.validate_type! 'hehe', B
    B.new.validate_type! :hehe, A
  end

  def test_validate_type_passes_when_any_match
    B.new.validate_type! B, String
    B.new.validate_type! String, A
  end

  def test_validate_type_allows_primatives
    true.validate_type! true
    false.validate_type! false
    nil.validate_type! nil
    nil.validate_type! NilClass
    nil.validate_type! nil, B
  end

  def test_validate_type_fail
    assert_raises(TypeValidationError){ B.new.validate_type! String }
  end

  def test_validate_type_fail_with_name
    assert_raises(TypeValidationError){ B.new.validate_type! 'hehe', String }
    assert_raises(TypeValidationError){ B.new.validate_type! :hehe, String }
  end

  def test_validate_type_fail_uses_name_in_errmsg
    3.validate_type! 'hehe', String
    raise "Error expected."
  rescue => e
    assert_match /for hehe/, e.to_s
  end

  #---------------------------------------------------------------------------------------------------------------------

  def test_validate_lvar_type!
    hehe= 123
    :hehe.validate_lvar_type!{ Fixnum }
    :hehe.validate_lvar_type!{ [nil,Fixnum] }
    assert_raises(TypeValidationError){ :hehe.validate_lvar_type!{ String }}
  end

  def test_validate_lvar_type_uses_name_in_errmsg
    hehe= 'no'
    :hehe.validate_lvar_type!{ Fixnum }
    raise "Error expected."
  rescue => e
    assert_match /for hehe/, e.to_s
  end
end
