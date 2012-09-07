module Kernel

  # Alternate implementation of `at_exit` that preserves the exit status (unless you call `exit` yourself and an error
  # is raised).
  #
  # The initial driver for this was that using `at_exit` to clean up global resources in RSpec tests, RSpec's exit
  # status would be lost which means CI processes and such were unable to tell whether there were test failures.
  #
  # @return [Proc] Whatever `at_exit` returns.
  def at_exit_preserving_exit_status(&block)
    at_exit {
      status= $!.respond_to?(:status) ? $!.status : 0
      block.()
      exit status
    }
  end
end

