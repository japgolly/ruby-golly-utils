require 'golly-utils/ruby_ext/deep_dup'

module GollyUtils
  module Callbacks

    def self.included(base)
      base.send :include, InstanceMethods
      base.send :include, InstanceAndClassMethods
      base.extend InstanceAndClassMethods
      base.extend ClassMethods
    end

    #-------------------------------------------------------------------------------------------------------------------

    module ClassMethods

      def define_callbacks(*callbacks)
        callbacks.each do |name|
          name= _norm_callback_key(name)
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

    module InstanceAndClassMethods

      private
      def _norm_callback_key(key)
        key.to_sym
      end

    end

    #-------------------------------------------------------------------------------------------------------------------

    module InstanceMethods

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
