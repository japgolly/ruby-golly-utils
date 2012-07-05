require 'golly-utils/delegator'

module GollyUtils

  # A fake IO implmentation that writes data to multiple underlying IO objects.
  class MultiIO < Delegator

    # @param targets Real IO objects.
    def initialize(*targets)
      super *targets, delegate_to: :all
    end
  end
end
