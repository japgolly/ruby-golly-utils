# encoding: utf-8
require_relative '../../bootstrap/unit'
require 'golly-utils/ruby_ext/options'

class OptionsTest < MiniTest::Unit::TestCase

  def test_nop_when_all_keys_valid
    {a:1,b:2}.validate_option_keys :a, :b
    {a:1,b:2}.validate_option_keys :a, :b, :c
  end

  def test_nop_when_hash_empty
    {}.validate_option_keys :a, :b
  end

  def test_error_when_extra_keys
    assert_raises(RuntimeError){ {a:1,b:2}.validate_option_keys :a }
  end

  def test_error_msg_contains_all_invalid_key_names
    {aaa:1,'bbb' => 2, x:5}.validate_option_keys :x
    flunk 'Error expected.'
  rescue => e
    assert_match /:aaa/, e.to_s
    assert_match /"bbb"/, e.to_s
    refute_match /x/, e.to_s
  end

end
