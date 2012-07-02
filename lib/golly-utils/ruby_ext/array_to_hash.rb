class Array

  # Converts the array to a hash where the values are the array elements and the keys are provided by calling a given
  # block.
  #
  # @example
  #   ['m','abc'].to_hash_keyed_by{ |v| v.length }       # => {1 => 'm', 3 => 'abc}
  def to_hash_keyed_by(raise_on_duplicate_keys=true, &key_provider)
    h= {}
    each {|e|
      k= key_provider.call(e)
      raise "Duplicate key: #{k.inspect}" if raise_on_duplicate_keys and h.has_key?(k)
      h[k]= e
    }
    h
  end

  # Converts the array to a hash where the keys are the array elements and the values are provided by either calling a
  # given block, or using a fixed, provided argument.
  #
  # @example
  #   [2,5].to_hash_with_values('x')                 # => {2 => 'x', 5 => 'x'}
  #   [2,5].to_hash_with_values{ |k| 'xo' * k }      # => {2 => 'xoxo', 5 => 'xoxoxoxoxo'}
  def to_hash_with_values(value=nil)
    h= {}
    each {|e| h[e]= block_given? ? yield(e) : value}
    h
  end
end
