class Class

  # @!visibility private
  def inherited other
    super if defined? super
  ensure
    ( @subclasses ||= [] ).push(other).uniq!
  end

  # Returns a list of classes that extend this class, directly or indirectly (as in subclasses of subclasses).
  #
  # @example
  #   # Given the following class heirarchy:
  #   #   A
  #   #   |
  #   #   +--B
  #   #   |  +--B1
  #   #   |  +--B2
  #   #   |
  #   #   +--C
  #
  #   A.subclasses         # => [B1, B2, C]
  #   A.subclasses(false)  # => [B1, B2, C]
  #   A.subclasses(true)   # => [B, B1, B2, C]
  #
  # @param include_subclassed_nodes If `true` then classes extended by other classes are returned. If `false` then you
  #     only get the end nodes.
  # @return [Array<Class>] An array of all subclasses.
  def subclasses(include_subclassed_nodes = false)
    @subclasses ||= []
    classes= @subclasses.inject( [] ) {|list, subclass| list.push subclass, *subclass.subclasses }
    classes.reject! {|c| classes.any?{|i| c != i and c.subclasses.include?(i) }} unless include_subclassed_nodes
    classes
  end
end

class Object
  # Returns the class hierarchy of a given instance or class.
  #
  # @example
  #   Fixnum.superclasses  # <= [Fixnum, Integer, Numeric, Object, BasicObject]
  #   100.superclasses     # <= [Fixnum, Integer, Numeric, Object, BasicObject]
  #
  # @return [Array<Class>] An array of classes starting with the current class, descending to `BasicObject`.
  def superclasses
    if self == BasicObject
      [self]
    elsif self.is_a? Class
      [self] + self.superclass.superclasses
    else
      self.class.superclasses
    end
  end

  # Indicates that a type validation check has failed.
  class TypeValidationError < RuntimeError
  end

  # Validates the type of the current object.
  #
  # @example
  #     3     .validate_type nil, Numeric
  #     nil   .validate_type nil, Numeric
  #     'What'.validate_type nil, Numeric   # <= raises TypeValidationError
  #
  #     # Ensures that f_debug is boolean
  #     f_debug.validate_type! 'the debug flag', true, false
  #
  # @overload validate_type!(name = nil, *valid_classes)
  #   @param [nil|Symbol|String] name The name of the object being checked (i.e. `self`).
  #     This only used in the error message and has no functional impact.
  #   @param [Array<Class>] valid_classes One or more classes that this object is allowed to be. Ruby primatives will
  #     automatically be translated to the corresponding class.
  # @return [self] If validation passes.
  # @raise [TypeValidationError] If validation fails.
  # @see Symbol#validate_lvar_type!
  def validate_type!(*args)
    name= args.first.is_a?(String) || args.first.is_a?(Symbol) ? args.shift : nil
    classes= args.map{|a| RUBY_PRIMATIVE_CLASSES[a] || a }
    raise "You must specify at least one valid class." if classes.empty?

    unless classes.any?{|c| self.is_a? c }
      for_name= name ? " for #{name}" : ''
      raise TypeValidationError, "Invalid type#{for_name}: #{self.class}\nValid types are: #{classes.map(&:to_s).sort.join ', '}."
    end
    self
  end


  # @!visibility private
  RUBY_PRIMATIVE_CLASSES= Hash[ [nil,true,false].map{|p|[p,p.class]} ].freeze
end

class Symbol
  # Validates the type of a local variable.
  #
  # @example
  #   def save_person(name, eyes)
  #     # Validate args
  #     :name.validate_lvar_type!{ String }
  #     :eyes.validate_lvar_type!{ [nil,Fixnum] }
  #
  #     # Do other stuff
  #     # ...
  #   end
  #
  # @yield Calls a given block once to get the list of valid classes. The block must have access to the local variable.
  # @yieldreturn [Class|Array<Class>] The given block should return one or more classes.
  # @return [true] If validation passes.
  # @raise [TypeValidationError] If validation fails.
  # @see Object#validate_type!
  def validate_lvar_type!(&block)
    name= self
    raise "You must provide a block that returns one or more valid classes for #{name}." unless block
    classes= [block.()].flatten
    v= block.send(:binding).eval(name.to_s)
    v.validate_type! name, *classes
    true
  end
end
