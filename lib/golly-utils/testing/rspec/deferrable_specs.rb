module GollyUtils
  module Testing

    # With this module you can create specs that don't start running until manually started elsewhere in another spec.
    #
    # This is only really useful when writing integration tests in spec format, where specs (aka examples) are not
    # isolated tests but single components of a larger-scale test. This is especially the case when checking
    # asynchronous events, or managing dependencies on state of an external entity.
    #
    # ## Usage
    # * Extend (not include) {DeferrableSpecs}.
    # * Create specs/examples using {ClassMethods#deferrable_spec deferrable_spec}.
    # * In other specs/examples, call {InstanceMethods#start_deferred_tests start_deferred_tests} to start deferred tests.
    #
    # @example
    #     describe 'Integration test #2' do
    #       extend GollyUtils::Testing::DeferrableSpecs
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

      # @!visibility private
      def self.extended(base)
        base.send :include, InstanceMethods
        base.extend ClassMethods
        base.instance_eval{ @deferrable_specs= {} }
      end

      module ClassMethods
        # @!visibility private
        attr_reader :deferrable_specs

        # Declares a test case that will start paused and not run until allowed within another test case.
        #
        # @param [Symbol] key A unique key that will later be used to refer back to this test case.
        # @param [String] name The name of the test case.
        # @raise If the given key has already been used.
        # @see InstanceMethods#start_deferred_tests
        def deferrable_spec(key, name, &block)
          raise "Invalid test key; please pass a Symbol." unless key.is_a?(Symbol)
          raise "Invalid test name; please pass a String." unless name.is_a?(String)
          raise "You must provide a block of test code. This test needs to do something." if block.nil?
          raise "The key #{key.inspect} has already been used." if deferrable_specs[key]
          deferrable_specs[key]= {block: block}
          class_eval <<-EOB
            it(#{name.inspect}){ deferred_join #{key.inspect} }
          EOB
        end

      end

      module InstanceMethods


        # Triggers one or more deferred tests to start running in the background.
        #
        # @param [Symbol] first_key The identifying key of the deferred test to start. (The name must match that given
        #     in {ClassMethods#deferrable_spec}).
        # @param [Array<Symbol>] other_keys Keys of additional tests to start.
        # @raise If a test name is invalid (i.e. hasn't been declared).
        # @raise If a test has already been started.
        # @return [true]
        def start_deferred_tests(first_key,*other_keys)
          ([first_key]+other_keys).flatten.uniq.each do |key|
            raise "Unknown defferable test: #{key}" unless d= self.class.deferrable_specs[key]
            raise "Test already started: #{key}" if d[:thread]
            s= self.dup
            d[:thread]= Thread.new{ s.instance_eval &b }
          end
          true
        end

        alias start_deferred_test start_deferred_tests

        private

        # Waits for a deferred test to run in the background and complete.
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
end
