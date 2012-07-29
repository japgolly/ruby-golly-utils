module GollyUtils
  module Testing
    module Helpers

      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        SELF= self
      end

    end
  end
end
