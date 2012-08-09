# encoding: utf-8
require_relative '../bootstrap/unit'
require 'golly-utils/attr_declarative'

class AttrDeclarativeTest < MiniTest::Unit::TestCase

  class Abc
    include GollyUtils::AttrDeclarative
    attr_declarative :cow
    attr_declarative :horse, :horse2, default: 246
  end

  def test_acts_like_attribute
    a= Abc.new
    assert_nil a.cow
    a.cow= 12
    assert_equal 12, a.cow
  end

  def test_default
    a= Abc.new
    assert_equal 246, a.horse
    assert_equal 246, a.horse2
    a.horse= 'hehe'
    assert_equal 'hehe', a.horse
    assert_equal 246, a.horse2
  end

  class Abc2 < Abc
    cow 777
  end
  def test_subclasses_can_change_defaults
    a= Abc2.new
    assert_equal 777, a.cow
    a.cow= 12
    assert_equal 12, a.cow
    assert_equal 777, Abc2.new.cow
    assert_nil Abc.new.cow
  end

  class Abc3 < Abc2; end
  def test_subclasses_inherit_parents_declarations
    assert_equal 777, Abc3.new.cow
    assert_nil Abc.new.cow
  end

  def test_instances_setting_to_nil
    assert_nil Abc.new.tap{|x| x.cow= nil}.cow
    assert_nil Abc2.new.tap{|x| x.cow= nil}.cow
    assert_nil Abc3.new.tap{|x| x.cow= nil}.cow
  end

  class Abc4 < Abc
    cow nil
  end
  def test_subclass_with_nil_default
    assert_nil Abc.new.cow
    assert_equal 777, Abc3.new.cow
    assert_nil Abc4.new.cow
  end

  class Seikima
    include GollyUtils::AttrDeclarative
    attr_declarative ok: 'sweet'
  end
  def test_quik_syntax
    assert_equal 'sweet', Seikima.new.ok
  end
end
