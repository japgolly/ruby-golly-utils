require 'golly-utils/ruby_ext/deep_dup'

module GollyUtils
  # A very simple callback mechanism for use within a single class heirarchy.
  #
  # It is primiarily meant to be used as a replacement for method overriding in external subclasses; the problem with
  # that approach being a) it's unclear with methods are required/overrides, and b) if the wrong method name is used
  # there is no early feedback - the erronously named method will simply never be invoked and the super-method will not
  # receive the intended modification.
  #
  # It allows:
  #
  # 1. A class to define named callback point.
  # 2. Subclasses to supply callbacks to specific points by name.
  # 3. Ability to run all callbacks for a given callback point.
  #
  # Unlike Rails' callbacks implementation, this deliberately doesn't provide before/after/around functionality, nor a
  # chain-like structure where the return value of one callback can affect the determinism of other callbacks being
  # invoked.
  #
  # ## Usage
  #
  # * In your superclass:
  #   1. Include {Callbacks}.
  #   2. Use {ClassMethods#define_callbacks} in the class definition.
  #   3. Call {InstanceMethods#run_callbacks} in your code.
  # * In subclasses:
  #   1. Supply a callback by declaring the callback name in the class definition, followed by a block of code.
  #
  # @example
  #
  #   class Engine
  #     include GollyUtils::Callbacks
  #
  #     define_callback :start
  #
  #     def start
  #       puts "About to start..."
  #       run_callbacks :start
  #       puts "Running."
  #     end
  #   end
  #
  #   class CustomEngine < Engine
  #     start do
  #       puts "---> STARTING!!!"
  #     end
  #   end
  #
  #   CustomEngine.new.start    # => About to start...
  #                             # => ---> STARTING!!!
  #                             # => Running.
  module Callbacks

    # @!visibility private
    def self.included(base)
      base.send :include, InstanceMethods
      base.send :include, InstanceAndClassMethods
      base.extend InstanceAndClassMethods
      base.extend ClassMethods
    end

    #-------------------------------------------------------------------------------------------------------------------

    module ClassMethods

      # Create one or more callback points for this class and its children.
      #
      # @param [Array<String, Symbol>] callbacks The callback name(s).
      # @return [void]
      # @raise If the callback has already been defined, or a method with that name already exists.
      # @see Callbacks
      # @see InstanceMethods#run_callbacks
      def define_callbacks(*callbacks)
        callbacks.each do |name|
          name= _norm_callback_key(name)

          if self.methods.include?(name.to_sym)
            raise "Can't create callback with name '#{name}'. A method with that name already exists."
          end

          _callbacks[name] ||= {}
          class_eval <<-EOB
            def self.#{name}(&block)
              v= (_callbacks[#{name.inspect}] ||= {})
              (v[:procs] ||= [])<< block
            end
          EOB
        end
      end
      alias :define_callback :define_callbacks

      private

      def _callbacks
        @callbacks ||= {}
      end

      def _get_callback_procs(name)
        name_verified= false
        results= []

        # Get local
        if local= _callbacks[name]
          name_verified= true
          results.concat local[:procs] if local[:procs]
        end

        # Get inherited
        if superclass.private_methods.include?(:_get_callback_procs)
          n,r = superclass.send(:_get_callback_procs,name)
          name_verified ||= n
          results.concat r
        end

        [name_verified,results]
      end

    end

    #-------------------------------------------------------------------------------------------------------------------

    # @!visibility private
    module InstanceAndClassMethods

      private
      def _norm_callback_key(key)
        key.to_sym
      end

    end

    #-------------------------------------------------------------------------------------------------------------------

    module InstanceMethods

      # Run all callbacks provided for one or more callback points.
      #
      # @param [Array<String, Symbol>] callbacks The callback name(s).
      # @return [void]
      # @raise If one of the provided callback names hasn't been declared for this class.
      # @see Callbacks
      # @see ClassMethods#define_callbacks
      def run_callbacks(*callbacks)
        callbacks.each do |name|
          name= _norm_callback_key(name)
          name_verified,results = self.class.send :_get_callback_procs, name
          raise "There is no callback defined with name #{name}." unless name_verified
          results.each{|cb| cb.call }
        end
        true
      end
      alias :run_callback :run_callbacks

    end
  end
end
