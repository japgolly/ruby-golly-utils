module GollyUtils
  # Mixin that enriches Ruby's `ENV`.
  #
  # @note This is mixed-in to `ENV` automatically.
  module EnvHelpers

    # Parses an environment variable that is expected to be a boolean.
    #
    # Regardless of case,
    #
    # * the following values are interpretted as positive: `1, y, yes, t, true, on, enabled`
    # * the following values are interpretted as negative: `0, n, no, f, false, off, disabled`
    #
    # @param [String] key The `ENV` key. The environment variable name.
    # @param [Boolean, nil] default The value to return if there is no environment variable of given key.
    # @return [Boolean,nil] The result of parsing the env var value, else `default`.
    def boolean(key, default=nil)
      return default unless self.has_key?(key)
      v= self[key]
      return true if v =~ /^\s*(?:[1yt]|yes|true|on|enabled?)\s*$/i
      return false if v =~ /^\s*(?:[0nf]|no|false|off|disabled?)\s*$/i
      STDERR.puts "Unable to parse boolean value #{v.inspect} for key #{key.inspect}."
      default
    end

    alias yes? boolean
    alias on? boolean
    alias enabled? boolean

    # Parses an environment variable and checks if it indicates a negative boolean value.
    #
    # @param (see #boolean)
    # @return [Boolean,nil] The result of parsing the env var value and it indicating the negative, else `default`.
    def no?(key, default=nil)
      !boolean(key, default)
    end
    alias off? no?
    alias disabled? no?

  end
end

# Add helpers to ENV
ENV.send :extend, GollyUtils::EnvHelpers
