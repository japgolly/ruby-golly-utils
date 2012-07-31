require 'golly-utils/testing/rspec/base'
require 'golly-utils/ruby_ext/enumerable'

module GollyUtils::Testing::RSpecMatchers

  #-----------------------------------------------------------------------------------------------------------------

  # @!visibility private
  class EqualsArray

    def initialize(expected)
      raise "Array expected, not #{expected.inspect}" unless expected.is_a?(Array)
      @expected= expected
    end

    def matches?(tgt)
      raise "Array expected, not #{tgt.inspect}" unless tgt.is_a?(Array)
      @tgt= tgt
      tgt == @expected
    end

    def failure_message_for_should
      @common= @tgt & @expected
      @missing= @expected - @common - @tgt
      @extra= @tgt - @common - @expected

      msg= unless @missing.empty? and @extra.empty?
          # Element mismatch
          m("Missing",@missing) + m("Unexpected",@extra)
        else
          # Check freq differences
          tgt_freq= @tgt.frequency_map
          expected_freq= @expected.frequency_map
          freq_diff= tgt_freq.inject({}){|h,kv|
            e,a = kv
            diff= a - expected_freq[e]
            h[e]= diff unless diff == 0
            h
          }
          if !freq_diff.empty?
            # Freq differences
            "Both arrays contain the same elements but have different frequencies of occurrance.\nFrequency differences: (neg=not enough, pos=too many)\n  #{freq_diff.inspect}"
          elsif @tgt.sort_by(&:to_s) == @expected.sort_by(&:to_s)
            # Order difference
            "They're in different orders." + m("Actual",@tgt,false) + m("Expected",@expected,false)
          else
            # Unknown difference
            m("Actual",@tgt,false) + m("Expected",@expected,false)
          end
        end

      "expected that arrays would match. #{msg}"
    end

    def failure_message_for_should_not
      "expected that arrays would not match." + m("Contents",@expected)
    end

    private
    def m(name, array, sort=true)
      return '' if array.empty?
      array= array.sort_by(&:to_s) if sort
      "\n#{name} elements: #{array.inspect}"
    end
  end

  # Passes if an array is the same as the target array.
  #
  # The advantage of calling this rather than `==` is that the error messages on failure here are customised for array
  # comparison and will provide much more useful description of why the arrays don't match.
  #
  # @note The order and frequency of elements matters; call `sort` or `uniq` first if required.
  #
  # @example
  #   %w[a a b].should equal_array %w[a a b]
  #   %w[b a b].should_not equal_array %w[a a b]
  #   files.should equal_array(expected)
  def equal_array(expected)
    return be_nil if expected.nil?
    EqualsArray.new(expected)
  end

  #-----------------------------------------------------------------------------------------------------------------

end
