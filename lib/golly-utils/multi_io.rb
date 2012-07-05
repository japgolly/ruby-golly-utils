module GollyUtils

  # A fake IO implmentation that writes data to multiple underlying IO objects.
  class MultiIO

    # @param targets Real IO objects.
    def initialize(*targets)
       @targets = targets
    end

    def write(*args)
      @targets.each {|t| t.write(*args) }
    end

    def close
      @targets.each(&:close)
    end
  end
end
