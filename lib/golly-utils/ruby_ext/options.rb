class Hash

  # Checks that all keys in this hash are part of a specific set; fails if not.
  #
  # @param [Array] valid_keys A set of valid keys.
  # @param [String] error_msg A message to include in the error when raised.
  # @return [self]
  # @raise Invalid keys are present.
  def validate_keys(valid_keys, error_msg = "Invalid hash keys")
    invalid= self.keys - [valid_keys].flatten
    unless invalid.empty?
      raise "#{error_msg}: #{invalid.sort_by(&:to_s).map(&:inspect).join ', '}"
    end
    self
  end

  # Checks that all keys in this hash are part of a specific set; fails if not.
  #
  # Differs from {#validate_keys} by providing an option-related error message.
  #
  # @param valid_keys A set of valid keys.
  # @return [self]
  # @raise Invalid keys are present.
  def validate_option_keys(*valid_keys)
    validate_keys valid_keys, "Invalid options provided"
  end

end
