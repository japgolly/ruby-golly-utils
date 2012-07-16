# encoding: utf-8
require_relative '../bootstrap/unit'
require 'golly-utils/attr_declarative'

class AttrDeclarativeTest < MiniTest::Unit::TestCase

  class Abc
    include GollyUtils::AttrDeclarative
    attr_declarative :cow
    attr_declarative :horse, default: 246
  end

  def test_acts_like_attribute
    a= Abc.new
    assert_nil a.cow
    a.cow{ 12 }
    assert_equal 12, a.cow
  end

  def test_default
    a= Abc.new
    assert_equal 246, a.horse
    a.horse{ 'hehe' }
    assert_equal 'hehe', a.horse
  end

  class Abc2 < Abc
    cow{ 777 }
  end
  def test_subclasses_can_change_defaults
    a= Abc2.new
    assert_equal 777, a.cow
    a.cow{ 12 }
    assert_equal 12, a.cow
    assert_equal 777, Abc2.new.cow
    assert_nil Abc.new.cow
  end

  class Abc3 < Abc2; end
  def test_subclasses_inherit_parents_declarations
    assert_equal 777, Abc3.new.cow
  end

  class Dynamic < Abc
    $cow= 123
    cow{ $cow }
  end
  def test_class_declarations_arent_evaluated_until_needed
    a= Dynamic.new
    $cow= 456
    assert_equal 456, a.cow
  end

end
