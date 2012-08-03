# encoding: utf-8
require_relative '../bootstrap/unit'
require 'golly-utils/callbacks'

class CallbacksTest < MiniTest::Unit::TestCase

  VALUES= []

  def setup
    VALUES.clear
  end

  class Base
    include GollyUtils::Callbacks
    define_callback :base
    def self.record(v); CallbacksTest::VALUES << v end
    def self.run(*args)
      o= self.new
      o.run(*args)
      CallbacksTest::VALUES
    end
  end

  class Omg < Base
    define_callback :wow
    def run; run_callback :wow end
  end
  def test_none; assert_equal [], Omg.run; end

  class Omg1 < Omg
    wow{ record 1 }
  end
  def test_one; assert_equal [1], Omg1.run; end

  class Omg2 < Omg
    wow{ record 1 }
    wow{ record 2 }
  end
  def test_multiple_callees_for_single_callback; assert_equal [1,2], Omg2.run; end

  class Omg1H < Omg1
    wow{ record 3 }
  end
  def test_callees_inherited; assert_equal [3,1], Omg1H.run; end

  class Sweet < Omg1
    define_callbacks :dude, :sweet
    wow{ record 7 }
    dude{ record 60 }
    sweet{ record 100 }
    dude{ record 50 }
    def run
      run_callback :wow
      run_callback :base
      self.class.record 666
      run_callbacks :sweet, :dude
    end
  end
  def test_everything; assert_equal [7,1,666,100,60,50], Sweet.run; end

  class Fail < Base
    def self.what; 135 end
  end
  def test_callbacks_dont_overwrite_class_methods
    Fail.send :define_callback, :this_should_work
    assert_equal 135, Fail.what
    Fail.send :define_callback, :what
    flunk 'Exception expected. Callbacks are supposed to raise an error a method with the callback name already exists.'
  rescue => e
    assert e.to_s['what'], "Error message doesn't include the conflicting method/callback name.\nErrMsg: #{e}"
    assert_equal 135, Fail.what
  end

  class Args < Base
    base{ |i| record (i || 0)+5 }
  end

  def test_run_callback_with_args
    Args.new.run_callback :base, 4
    assert_equal [9], VALUES
  end

  def test_run_callbacks_with_args_array
    Args.new.run_callbacks :base, args: [3]
    assert_equal [8], VALUES
  end

  def test_run_callbacks_with_args_nonarray
    Args.new.run_callbacks :base, args: 13
    flunk "Failure expected."
  rescue => e
    assert_match /array/i, e.to_s
  end

  def test_run_callbacks_fails_with_unrecognisable_options
    Args.new.run_callbacks :base, stuff: [3]
    flunk "Failure expected."
  rescue => e
    assert_match /stuff/, e.to_s
  end

end
