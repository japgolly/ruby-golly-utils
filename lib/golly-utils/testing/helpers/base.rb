module GollyUtils
  # This module is the parent module for utility code that client may find useful when writing tests.
  #
  # (This has nothing to do with GollyUtils' own, internal tests.)
  module Testing
    module Helpers

      # @!visibility private
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        # @!visibility private
        SELF= self
      end

    end
  end
end
