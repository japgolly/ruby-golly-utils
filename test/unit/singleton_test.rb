# encoding: utf-8
require_relative '../bootstrap/unit'
require 'golly-utils/singleton'

class SingletonTest < MiniTest::Unit::TestCase

  class SymphonyX
    include GollyUtils::Singleton
    attr_accessor :hehe
    def hi; 123 end

    def class_lvl; false end; def self.class_lvl; true end

    hide_singleton_methods /^ignore/
    def ignore_me; nil end
    def me_too; nil end
    hide_singleton_methods 'me_too'
  end

  def test_ruby_singleton
    mods= SymphonyX.included_modules.map(&:to_s)
    assert mods.include?('Singleton'), "Doesn't extend Ruby Singleton. #{mods.sort.inspect}"
  end

  def test_provides_class_level_access
    assert_equal 123, SymphonyX.hi
  end

  def test_doesnt_override_class_methods
    assert_equal true, SymphonyX.class_lvl, "Should be calling self.class_lvl, not the instance method."
  end

  def test_hides_methods_by_regex
    assert_raises(NoMethodError){ SymphonyX.ignore_me }
  end

  def test_hides_methods_by_string
    assert_raises(NoMethodError){ SymphonyX.me_too }
  end
end