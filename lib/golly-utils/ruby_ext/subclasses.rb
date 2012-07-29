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
