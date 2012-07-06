module GollyUtils

  # With this module you can create specs that don't start running until manually started elsewhere in another spec.
  #
  # This is only really useful when writing integration tests in spec format, where specs (aka examples) are not
  # isolated tests but single components of a larger-scale test. This is especially the case when checking
  # asynchronous events, or managing dependencies on state of an external entity.
  #
  # ### Usage:
  # * Extend `GollyUtils::DeferrableSpecs`
  # * Create specs/examples using `deferrable_spec`
  # * In other specs/examples, call `start_deferred_test` to start deferred tests.
  #
  # @example
  #     describe 'Integration test #2' do
  #       extend GollyUtils::DeferrableSpecs
  #
  #       it("Register client, notices and default prefs") do
  #         scenario.register_client
  #         scenario.register_notification_groups
  #         scenario.register_notices
  #         scenario.set_default_preferences
  #
  #         start_deferred_test :email1
  #         start_deferred_test :email2
  #         start_deferred_test :mq
  #       end
  #
  #       # Deferred until registration of client, notices and preferences are complete
  #       deferrable_spec(:email1, "Sends emails (to unregistered contacts)") do
  #         assert_sends_email ...
  #       end
  #
  #       ...
  #
  #     end
  module DeferrableSpecs
    def self.extended(base)
      base.send :include, InstanceMethods
      base.extend ClassMethods
      base.instance_eval{ @deferrable_specs= {} }
    end

    module ClassMethods
      attr_reader :deferrable_specs

      def deferrable_spec(key, name, &block)
        deferrable_specs[key]= {block: block}
        class_eval <<-EOB
          it(#{name.inspect}){ deferred_join #{key.inspect} }
        EOB
      end

    end

    module InstanceMethods

      def start_deferred_tests(first_key,*other_keys)
        ([first_key]+other_keys).flatten.uniq.each do |key|
          raise "Unknown defferable test: #{key}" unless d= self.class.deferrable_specs[key]
          raise "Test already started: #{key}" if d[:thread]
          raise "Test block missing." unless b= d[:block]
          s= self.dup
          d[:thread]= Thread.new{ s.instance_eval &b }
        end
        true
      end

      alias start_deferred_test start_deferred_tests

      def deferred_join(key)
        raise "Unknown defferable test: #{key}" unless d= self.class.deferrable_specs[key]
        if t= d[:thread]
          t.join
        else
          #raise "Test hasn't started: #{key}"
          warn "Deferrable spec #{key.inspect} wasn't deferred. Start it elsewhere with start_deferred_test #{key.inspect}"
          raise "Test block missing." unless b= d[:block]
          b.call
        end
      end

    end
  end
end
