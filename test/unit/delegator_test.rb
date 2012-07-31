# encoding: utf-8
require_relative '../bootstrap/unit'
require 'golly-utils/delegator'

class DelegatorTest < MiniTest::Unit::TestCase

  class A
    def a; 1; end
    def c; 10; end
    def add(a,b,c) a+b+c end
    protected
    def prot; 666; end
    private
    def pri; -1; end
  end

  class B
    def b; 2; end
    def c; 20; end
  end

  def na; A.new end
  def nb; B.new end
  def nd(*args) GollyUtils::Delegator.new(*args) end

  def test_simple_delegation
    d= nd(na,nb)
    assert_equal 1, d.a
    assert_equal 2, d.b
  end

  def test_delegation_with_multiple_args
    assert_equal 15, nd(na).add(3,5,7)
  end

  def test_conflict_calls_first_by_default
    assert_equal 10, nd(na,nb).c
  end

  def test_conflict_calls_all
    assert_equal [10,20], nd(na,nb,delegate_to: :all).c
  end

  def test_respond_to_checks_delegatable
    d= nd(na,nb)
    assert d.respond_to?(:a)
    assert d.respond_to?(:b)
    assert d.respond_to?(:c)
    assert !d.respond_to?(:x)
  end

  def test_respond_to_checks_internal
    d= nd(na,nb)
    refute d.respond_to?(:xxx)
    d.instance_eval 'def xxx; end'
    assert d.respond_to?(:xxx)
  end

  def test_caching
    [true,false].each do |cache|
      a= na
      d= nd(a, cache: cache)
      assert_raises(NoMethodError){ d.x }
      def a.x; 123; end
      if cache
        assert_raises(NoMethodError){ d.x }
      else
        assert_equal 123, d.x
      end
    end
  end

  def test_method_whitelist__fixed
    d= nd(na,nb, method_whitelist: [:a, 'b'])

    assert d.respond_to?(:a)
    assert d.respond_to?(:b)
    assert !d.respond_to?(:c)

    assert_equal 1, d.a
    assert_equal 2, d.b
    assert_raises(NoMethodError){ d.c }
  end

  def test_method_whitelist__regex
    d= nd(na,nb, method_whitelist: /^[ac]$/)

    assert d.respond_to?(:a)
    assert !d.respond_to?(:b)
    assert d.respond_to?(:c)

    assert_equal 1, d.a
    assert_equal 10, d.c
    assert_raises(NoMethodError){ d.b }
  end

  def test_method_blacklist
    d= nd(na,nb, method_blacklist: [:a, 'b', /^ad{2}$/])

    assert !d.respond_to?(:a)
    assert !d.respond_to?(:b)
    assert d.respond_to?(:c)
    assert !d.respond_to?(:add)

    assert_equal 10, d.c
    assert_raises(NoMethodError){ d.a }
    assert_raises(NoMethodError){ d.b }
    assert_raises(NoMethodError){ d.add }
  end

  def test_protected_methods_not_allowed_by_default
    assert_raises(NoMethodError){ nd(na).prot }
  end

  def test_protected_methods_allowed_when_enabled
    assert_equal 666, nd(na, allow_protected: true).prot
  end

  def test_private_methods_not_allowed
    assert_raises(NoMethodError){ nd(na).pri }
    assert_raises(NoMethodError){ nd(na, allow_protected: true).pri }
  end
end
