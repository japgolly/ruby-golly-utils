require 'singleton'

module GollyUtils
  # Makes the including class a singleton.
  # Much like Ruby's `Singleton` module, with extra features.
  #
  # Features:
  #
  # * Target class includes Ruby's `Singleton` module too.
  # * Class methods are added to the target class that delegate to the singleton instance.
  #
  # @example
  #   class Stam1na
  #     include GollyUtils::Singleton
  #
  #     def band_rating
  #       puts 'AWESOME!!'
  #     end
  #   end
  #
  #   Stam1na.instance.band_rating  #=> AWESOME!!
  #   Stam1na.band_rating           #=> AWESOME!!
  module Singleton

    # @!visibility private
    def self.included(base)
      base.send :include, ::Singleton
      base.extend ClassMethods
      base.class_eval <<-EOB
        class << self
          alias :method_missing_before_gu_singleton :method_missing
          def method_missing(method, *args, &block)
            if method != :__gu_singleton_method_missing

              r= __gu_singleton_method_missing(self, method, *args, &block)
              unless ::GollyUtils::Singleton::NO_MATCH == r
                return r
              end

            end
            method_missing_before_gu_singleton method, *args, &block
          end
        end
      EOB
    end

    module ClassMethods

      # Prevents class-level delegate methods from being created for certain instance methods.
      #
      # @param [Array<Regexp|String>] matchers Either the name of the method, or a regex that matches methods.
      # @return [nil]
      def hide_singleton_methods(*matchers)
        r=  __gu_singleton_rejects
        r.concat matchers
        r.flatten!
        r.uniq!
        nil
      end

      private

      def __gu_singleton_rejects
        @__gu_singleton_rejects ||= []
      end

      # Called on `method_missing`. Rather than simply delegating the method call, it will instead see if there are any
      # delegate methods that haven't been created yet and if so, creates them. This results in improved performance and
      # less hits to `method_missing`.
      def __gu_singleton_method_missing(singleton_class ,method, *args, &block)
        methods= (singleton_class.instance.public_methods - singleton_class.methods)
        if rej= __gu_singleton_rejects
          methods.reject!{|m| m= m.to_s; rej.any?{|r| r === m }}
        end
        unless methods.empty?
          code= methods.map {|m| "def self.#{m}(*a,&b); self.instance.send :#{m},*a,&b; end" }
          singleton_class.class_eval(code.join "\n")
          return singleton_class.send(method,*args,&block) if methods.include?(method)
        end
        ::GollyUtils::Singleton::NO_MATCH
      end

    end

    # @!visibility private
    NO_MATCH= Object.new
  end
end
