require 'golly-utils/testing/rspec/base'

module GollyUtils::Testing::Helpers

  # Re-runs a given block until it:
  #
  # * indicates success by returning `true`
  # * fails by not returning `true` within a given time period.
  #
  # @example
  #   within(5).seconds{ 'Gemfile'.should exist_as_a_file }
  #
  # @param [Numeric] timeout The maximum number of time units (to be specified after a call to this) to wait for a
  #   condition to be met.
  # @see WithinTime
  def within(timeout)
    WithinTime.new(timeout)
  end

  # @see #within
  class WithinTime

    # @param [Numeric] timeout The maximum number of time units (to be specified after a call to this) to wait for a
    #   condition to be met.
    # @param [Numeric] sleep_time The number of seconds to wait after an unsuccessful attempt before trying again.
    def initialize(timeout, sleep_time=0.1)
      timeout= timeout.to_f
      raise unless timeout > 0
      @timeout= timeout

      sleep_time= sleep_time.to_f
      raise unless sleep_time > 0
      @sleep_time= sleep_time
    end
    def ms     (&block) run    0.001, block end
    def seconds(&block) run    1    , block end
    def minutes(&block) run   60    , block end
    def hours  (&block) run 3600    , block end
    alias :msec   :ms
    alias :second :seconds
    alias :sec    :seconds
    alias :minute :minutes
    alias :min    :minutes
    alias :hour   :hours
    alias :hr     :hours
    alias :hrs    :hours
    protected
    def run(factor_to_sec, block)
      timeout= @timeout * factor_to_sec
      sleep_time= @sleep_time * factor_to_sec
      start= Time.now
      while true

        begin
          block.call
          return true
        rescue RSpec::Expectations::ExpectationNotMetError => err
          sleep sleep_time
          raise err if (Time.now - start) > timeout
        end

      end
    end
  end

end
