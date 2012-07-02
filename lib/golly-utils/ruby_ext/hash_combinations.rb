class Hash

  # Given a hash where each value can be a single value or an array of potential values, this generate a hash for each
  # combination of values across all keys.
  #
  # @return [Array<Hash>]
  #
  # @example
  #   # Here key :a has 3 possible values, :b has 2, and :c and :d have only 1 each.
  #   x = {a:%w[x y z], b:[1,2], c:'true', d:nil}
  #
  #   x.value_combinations
  #   # will return:
  #
  #   [
  #    {a:'x', b:1, c:'true', d:nil},
  #    {a:'y', b:1, c:'true', d:nil},
  #    {a:'z', b:1, c:'true', d:nil},
  #    {a:'x', b:2, c:'true', d:nil},
  #    {a:'y', b:2, c:'true', d:nil},
  #    {a:'z', b:2, c:'true', d:nil},
  #   ]
  def value_combinations
    collect_value_combinations [], {}, keys
  end

  private

  def collect_value_combinations(results, tgt, remaining_keys)
    if remaining_keys.empty?
      results<< tgt
    else
      next_set_of_keys= remaining_keys[1..-1]
      k= remaining_keys[0]
      v= self[k]
      if v.kind_of?(Enumerable)
        v.each_entry {|v2|
          tgt2= tgt.dup
          tgt2[k]= v2
          collect_value_combinations results, tgt2, next_set_of_keys
        }
      else
        tgt[k]= v
        collect_value_combinations results, tgt, next_set_of_keys
      end
    end
    results
  end
end
