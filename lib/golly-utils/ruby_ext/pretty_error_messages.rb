class StandardError

  # Creates a string that provides more information (a backtrace) than the default `to_s` method.
  #
  # @return [String]
  def to_pretty_s
    "#{self.inspect}\n#{self.backtrace.map{|b| "  #{b}"}.join "\n"}"
  end
end
