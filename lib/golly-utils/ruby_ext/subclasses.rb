class Class
  def inherited other
    super if defined? super
  ensure
    ( @subclasses ||= [] ).push(other).uniq!
  end

  # Returns a list of classes that extend this class, directly or indirectly (as in subclasses of subclasses).
  #
  # @return [Array<Class>]
  def subclasses(include_subclassed_nodes = false)
    @subclasses ||= []
    classes= @subclasses.inject( [] ) {|list, subclass| list.push subclass, *subclass.subclasses }
    classes.reject! {|c| classes.any?{|i| c != i and c.subclasses.include?(i) }} unless include_subclassed_nodes
    classes
  end
end
