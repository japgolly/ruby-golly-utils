# encoding: utf-8
require_relative '../../bootstrap/unit'
require 'golly-utils/ruby_ext/env_helpers'

class EnvTest < MiniTest::Unit::TestCase
  KEY= 'golly_test_env'

  def test_boolean_on
    %w[1 yes on true y].each do |v|
      ENV[KEY]= v
      assert ENV.on?(KEY)
      assert ENV.yes?(KEY)
      assert ENV.enabled?(KEY)
      refute ENV.off?(KEY)
      refute ENV.no?(KEY)
      refute ENV.disabled?(KEY)
    end
  end

  def test_boolean_off
    %w[0 no off false n].each do |v|
      ENV[KEY]= v
      refute ENV.on?(KEY)
      refute ENV.yes?(KEY)
      refute ENV.enabled?(KEY)
      assert ENV.off?(KEY)
      assert ENV.no?(KEY)
      assert ENV.disabled?(KEY)
    end
  end

  def test_boolean_default
    ENV.delete KEY
    assert_nil ENV.boolean(KEY)
    assert_equal true, ENV.boolean(KEY,true)
    assert_equal false, ENV.boolean(KEY,false)
  end

  def test_boolean_defaults_to_off
    ENV.delete KEY
    refute ENV.on?(KEY)
    refute ENV.yes?(KEY)
    refute ENV.enabled?(KEY)
    assert ENV.off?(KEY)
    assert ENV.no?(KEY)
    assert ENV.disabled?(KEY)
  end
end
