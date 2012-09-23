require 'golly-utils/ruby_ext/deep_dup'
require 'golly-utils/ruby_ext/options'
require 'golly-utils/delegator'

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
  #
  # @example Also works in modules
  #   module SupportsStuff
  #     include GollyUtils::Callbacks
  #     define_callback :stuff
  #   end
  #
  #   class DoerOfStuff
  #     include SupportsStuff
  #     stuff{ puts 'Doing stuff!!' }
  #   end
  #
  #   def stuff_machine(anything_that_supports_stuff)
  #     puts "I'll take anything that SupportsStuff."
  #     anything_that_supports_stuff.run_callbacks :stuff
  #     puts "See!"
  #   end
  #
  #   stuff_machine DoerOfStuff.new  # => I'll take anything that SupportsStuff.
  #                                  # => Doing stuff!!
  #                                  # => See!
  #
  # @example Specifying callback run order
  #   class X
  #     on_action{ puts 'That thing happened.' }
  #   end
  #
  #   class Y < X
  #     on_action(priority: -1){ puts 'FIRST!' }
  #     on_action(priority:  1){ puts 'Last.' }
  #   end
  #
  #   Y.new.run_callback :on_action                # => FIRST!
  #                                                # => That thing happened.
  #                                                # => Last.
  module Callbacks

    # @!visibility private
    def self.included(base)
      if base.is_a?(Class)
        base.send :include, InstanceMethods
        base.extend ClassMethods
      else
        base.extend ModuleMethods
        base.class_eval <<-EOB
        class << self
          alias :included_without_gu_callbacks :included
          def included(base)
            included_without_gu_callbacks(base)
            __add_callbacks_when_included(base)
          end
        end
        EOB
      end
    end

    # @!visibility private
    def self.__norm_callback_key(key)
      key.to_sym
    end

    # List of valid options than can be provided when specifying callback procs.
    #
    # * `:priority` - Fixnum that declares the run order of the given proc. Defaults to 0 when option not provided or
    #   `nil`. A lower number indicates a preference to run earlier; a higher number, later.
    #
    #   For example, a callback of priority -5 will run before callbacks with priorities of 0, followed by a callback
    #   of 10.
    CALLBACK_PROC_OPTIONS= [:priority].freeze

    #-------------------------------------------------------------------------------------------------------------------

    # Provides methods that can be run within definitions of modules that include {Callbacks}.
    module ModuleMethods

      # Create one or more callback points that will be added to classes that include the enclosing module.
      #
      # @param (see GollyUtils::Callbacks::ClassMethods#define_callbacks)
      # @return [true]
      def define_callbacks(*callbacks)
        __module_callback_names.concat callbacks
        __module_callback_names.uniq!
        true
      end
      alias :define_callback :define_callbacks

      # Returns a list of all callbacks available to this module. (i.e. defined, inherited, and included.)
      #
      # @return [Array<Symbol>] Callback names.
      def callbacks
        c= __module_callback_names
        included_modules.each {|m|
          c.concat m.callbacks if m.respond_to? :callbacks
        }
        c.uniq.sort_by(&:to_s)
      end

      private
      def __add_callbacks_when_included(base)
        base.send :include, Callbacks
        names= __module_callback_names
        unless names.empty?
          base.class_eval "define_callbacks *#{names.inspect}"
        end
      end

      def __module_callback_names
        @__module_callbacks ||= []
      end
    end

    #-------------------------------------------------------------------------------------------------------------------

    # Provides methods that can be run within definitions of classes that include {Callbacks}.
    module ClassMethods

      # Create one or more callback points for this class and its children.
      #
      # @param [Array<String|Symbol>] callbacks The callback name(s).
      # @return [true]
      # @raise If the callback has already been defined, or a method with that name already exists.
      # @see Callbacks
      # @see InstanceMethods#run_callbacks
      def define_callbacks(*callbacks)
        callbacks.each do |name|
          name= ::GollyUtils::Callbacks.__norm_callback_key(name)

          if self.methods.include?(name.to_sym)
            raise "Can't create callback with name '#{name}'. A method with that name already exists."
          end

          _callbacks[name] ||= []
          class_eval <<-EOB
            def self.#{name}(options={}, &block)
              options.validate_option_keys *#{Callbacks}::CALLBACK_PROC_OPTIONS
              data= options.deep_dup.merge proc: block
              (_callbacks[#{name.inspect}] ||= []) << data
            end
          EOB
        end
        true
      end
      alias :define_callback :define_callbacks

      # Returns a list of all callbacks available to this class. (i.e. defined, inherited, and included.)
      #
      # @return [Array<Symbol>] Callback names.
      def callbacks
        c= superclass.respond_to?(:callbacks) ? superclass.callbacks : []
        c.concat _callbacks.keys
        c.uniq.sort_by(&:to_s)
      end

      private

      def _callbacks
        @callbacks ||= {}
      end

      def _get_callbacks_for(name)
        name_verified= false
        results= []

        # Get local
        if local= _callbacks[name]
          name_verified= true
          results.concat local
        end

        # Get inherited
        if superclass.private_methods.include?(:_get_callbacks_for)
          n,r = superclass.send(:_get_callbacks_for,name)
          name_verified ||= n
          results.concat r
        end

        [name_verified,results]
      end

    end

    #-------------------------------------------------------------------------------------------------------------------

    # Provides methods that are available to instances of classes that include {Callbacks}.
    module InstanceMethods

      # Run all callbacks provided for a single callback point.
      #
      # @param [String, Symbol] callback The callback name.
      # @param [Hash] options
      # @option options [Array] :args ([]) Arguments to pass to the callbacks.
      # @option options [nil|Object] :context (nil) If provided, code within callbacks will have access to methods
      #   available from the provided object.
      # @return [true]
      # @raise If the provided callback name hasn't been declared for this class.
      # @raise If unrecognised or invalid options are provided.
      # @see Callbacks
      # @see ClassMethods#define_callbacks
      def run_callback(callback, options={})
        options.validate_option_keys :context, :args

        # Validate callback name
        name= ::GollyUtils::Callbacks.__norm_callback_key(callback)
        name_verified,callbacks = self.class.send :_get_callbacks_for, name
        raise "There is no callback defined with name #{name}." unless name_verified

        # Validate options
        args= options[:args] || []
        raise "The :args option must provide an array. Invalid: #{args}" unless args.is_a?(Array)

        # Collect procs to run
        callback_procs= callbacks.sort_by{|d| d[:priority] || 0 }.map{|d| d[:proc] }

        # Run procs provided for callback
        callback_procs.each{|cb|
          if ctx= options[:context]
            dlg= GollyUtils::Delegator.new self, ctx, delegate_to: :first, allow_protected: true
            dlg.instance_eval &cb
          else
            cb.call *args
          end
        }

        true
      end

      # Run all callbacks provided for one or more callback points.
      #
      # @overload run_callbacks(*callbacks, options = {})
      #   @param [Array<String, Symbol>] callbacks The callback name(s).
      #   @param [Hash] options
      #   @option options [Array] args ([]) Arguments to pass to the callbacks.
      #   @option options [nil|Object] context (nil) If provided, code within callbacks will have access to methods
      #     available from the provided object.
      # @return [true]
      # @raise If one of the provided callback names hasn't been declared for this class.
      # @raise If unrecognised or invalid options are provided.
      # @see Callbacks
      # @see ClassMethods#define_callbacks
      def run_callbacks(*callbacks)
        options= callbacks.last.is_a?(Hash) ? callbacks.pop : {}

        # Run callbacks
        callbacks.each do |callback|
          run_callback callback, options
        end

        true
      end

    end
  end
end
