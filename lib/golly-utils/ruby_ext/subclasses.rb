class Class
  def inherited other
    super if defined? super
  ensure
    ( @subclasses ||= [] ).push(other).uniq!
  end

  # Returns a list of classes that extend this class, directly or indirectly (as in subclasses of subclasses).
  #
  # @return [Array<Class>]
  def subclasses
    @subclasses ||= []
    @subclasses.inject( [] ) do |list, subclass|
      list.push(subclass, *subclass.subclasses)
    end
  end
end
