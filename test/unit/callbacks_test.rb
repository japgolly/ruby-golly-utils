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
    Args.new.run_callback :base, args: [4]
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

  def test_run_callback_fails_with_unrecognisable_options
    Args.new.run_callback :base, stuff: [3]
    flunk "Failure expected."
  rescue => e
    assert_match /stuff/, e.to_s
  end

  def test_run_callbacks_fails_with_unrecognisable_options
    Args.new.run_callbacks :base, stuff: [3]
    flunk "Failure expected."
  rescue => e
    assert_match /stuff/, e.to_s
  end

  module TestModule
    include GollyUtils::Callbacks
    define_callback :from_mod
  end

  module TestModule2
    include TestModule
    define_callback :from_mod2
  end

  class WithMod
    include TestModule
    define_callback :bru
    def self.record(v); CallbacksTest::VALUES << v end
    def self.run(*args)
      o= self.new
      o.run_callback :from_mod
      CallbacksTest::VALUES
    end
    from_mod{ record 357 }
  end
  def test_with_module; assert_equal [357], WithMod.run; end

  def test_callbacks_class_method
    assert_equal [:base], Base.callbacks
    assert_equal [:base, :wow], Omg.callbacks
    assert_equal [:base, :wow], Omg2.callbacks
    assert_equal [:base, :dude, :sweet, :wow], Sweet.callbacks
  end
  def test_callbacks_module_method
    assert_equal [:from_mod], TestModule.callbacks
    assert_equal [:from_mod, :from_mod2], TestModule2.callbacks
  end
  def test_callbacks_class_with_module
    assert_equal [:bru, :from_mod], WithMod.callbacks
  end

  class Context
    attr_reader :good
    def make_good; @good= 'good' end
  end
  class ContextCallback
    include GollyUtils::Callbacks
    define_callback :go
    go { make_good }
  end
  def test_callback_with_context
    ctx= Context.new
    cc= ContextCallback.new
    cc.run_callback :go, context: ctx
    assert_equal 'good', ctx.good
  end

  class ContextCallback2 < ContextCallback
    attr_reader :local_too
    def hit_local_too; @local_too= 'yes' end
    go { hit_local_too }
  end
  def test_callback_with_context_can_access_local_too
    ctx= Context.new
    cc= ContextCallback2.new
    cc.run_callback :go, context: ctx
    assert_equal 'good', ctx.good
    assert_equal 'yes', cc.local_too
  end

  class CallbacksWithPri < Omg1
    wow(priority: 10){ record 66010 }
    wow(priority: -10){ record 16 }
  end
  def test_callbacks_with_priorities
    assert_equal [16,1,66010], CallbacksWithPri.run
  end
end
