# encoding: utf-8
require_relative '../../bootstrap/unit'
require 'golly-utils/ruby_ext/hash_combinations'

class HashCombinationsTest < MiniTest::Unit::TestCase

  def test_empty
    assert_equal [{}], {}.value_combinations
  end

  def test_array1_single2
    x= {a:false, b:[1,2], c:'true'}
    assert_arrays [{a:false,b:1,c:'true'},{a:false,b:2,c:'true'}], x.value_combinations
  end

  def test_array2_single1
    x= {a:%w[a b c], b:[1,2], c:'true', d:nil}
    assert_arrays [
      {a:'a', b:1, c:'true', d:nil},
      {a:'b', b:1, c:'true', d:nil},
      {a:'c', b:1, c:'true', d:nil},
      {a:'a', b:2, c:'true', d:nil},
      {a:'b', b:2, c:'true', d:nil},
      {a:'c', b:2, c:'true', d:nil},
    ], x.value_combinations
  end

  def assert_arrays(exp, act)
    assert_equal exp.sort_by(&:to_s), act.sort_by(&:to_s)
  end
end
