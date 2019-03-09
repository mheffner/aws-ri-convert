class SubsetSumRis
  def initialize
    # map subset sum -> list of ris
    @ri_map = {}
  end

  def empty?
    @ri_map.empty?
  end

  def add(sum, ri)
    @ri_map[sum] ||= []
    @ri_map[sum] << ri
    ri
  end

  def rm_ri(ri)
    @ri_map.each do |k, v|
      v.delete_if{|r| r.reserved_instances_id == ri.reserved_instances_id}
    end

    @ri_map.delete_if{|k, v| v.empty?}
  end

  # Select all the RIs that match the given sum amounts,
  # the tricky part is that sums may have dupes and we need
  # to return unique RIs that match
  #
  # XXX: this could be optimized
  #
  def select_all(sums)
    # Get a copy of values
    ris = values()

    ret = []
    sums.each do |sum|
      # find one, doesn't matter which
      found = ris.find{|r| r.instance_count == sum}

      raise "Can't find RI matching sum #{sum}" unless found

      ret << found

      # delete the one we found
      ris.delete_if{|r| r.reserved_instances_id == found.reserved_instances_id}
    end

    ret
  end

  def [](sum)
    r = @ri_map[sum]

    if r
      r.first
    else
      nil
    end
  end

  def []=(sum, value)
    add(sum, value)
  end

  def total_count
    k = self.keys
    k.inject(:+)
  end

  def keys
    keys = []
    @ri_map.each do |k, v|
      keys += [k] * v.length
    end

    keys.sort!
  end

  def values
    vals = []
    @ri_map.each do |k, v|
      vals += v
    end

    vals
  end

  def all
    list = []
  end
end

