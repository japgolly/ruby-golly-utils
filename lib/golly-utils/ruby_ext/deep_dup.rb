class Object
  # Creates a deep copy of the object. Where supported (arrays and hashes by default), object state will be duplicated
  # and used, rather than the original and duplicate objects sharing the same state.
  def deep_dup
    dup
  end
end

class Array
  # Creates a copy of the array with deep copies of each element.
  #
  # @see Object#deep_dup
  def deep_dup
    map(&:deep_dup)
  end
end

class Hash
  # Creates a copy of the hash with deep copies of each key and value.
  #
  # @see Object#deep_dup
  def deep_dup
    duplicate = {}
    each_pair do |k,v|
      duplicate[k.deep_dup]= v.deep_dup
    end
    duplicate
  end
end

[TrueClass, FalseClass, NilClass, Symbol, Numeric].each do |klass|
  klass.class_eval "def deep_dup; self end"
end
