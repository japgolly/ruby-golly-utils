module GollyUtils
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
