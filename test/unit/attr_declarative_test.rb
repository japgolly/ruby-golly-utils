# encoding: utf-8
require_relative '../bootstrap/unit'
require 'golly-utils/attr_declarative'

class AttrDeclarativeTest < MiniTest::Unit::TestCase

  class Abc
    attr_declarative :cow
    attr_declarative :horse, :horse2, default: 246
    attr_declarative :important, required: true
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
    important 666
  end
  def test_subclass_with_nil_default
    assert_nil Abc.new.cow
    assert_equal 777, Abc3.new.cow
    assert_nil Abc4.new.cow
  end

  class Seikima
    attr_declarative ok: 'sweet'
  end
  def test_quik_syntax
    assert_equal 'sweet', Seikima.new.ok
  end

  def test_required_fields_fail_when_undefined
    e= assert_raises(RuntimeError){ Abc.new.important }
  end

  def test_error_msg_when_required_field_missing_mentions_subclass_name
    e= assert_raises(RuntimeError){ Abc2.new.important }
    assert_match /Abc2/, e.message
  end

  def test_required_fields_works_as_normal_once_defined
    assert_equal 666, Abc4.new.important
    x= Abc.new
    x.important= 135
    assert_equal 135, x.important
  end

  def test_required_fields_can_be_set_to_nil
    x= Abc.new
    x.important= nil
    assert_nil x.important
  end
end
