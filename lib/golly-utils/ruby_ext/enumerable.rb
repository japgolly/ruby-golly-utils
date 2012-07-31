module Enumerable

  # Creates a map of all elements by the frequency that they occur.
  #
  # @example
  #   %w[big house big car].frequency_map  # => {"big"=>2, "car"=>1, "house"=>1}
  #
  # @return [Hash<Object,Fixnum>] Map of element to frequency.
  def frequency_map
    inject Hash.new do |h,e|
      h[e]= (h[e] || 0) + 1
      h
    end
  end

end
