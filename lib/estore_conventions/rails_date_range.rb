# untested, based off of a StackOverflow answer I put here:
# http://stackoverflow.com/questions/19093487/ruby-create-range-of-dates/19346914#19346914

class RailsDateRange < Range
  # step is similar to DateTime#advance argument
  def every(step, &block)
    c_time = self.begin.to_datetime
    finish_time = self.end.to_datetime
    foo_compare = self.exclude_end? ? :< : :<=

    arr = []
    while c_time.send( foo_compare, finish_time) do 
      if block_given?
        # optionally let invoker transform the array here
        c_time_v = yield c_time
      else
        c_time_v = c_time
      end
      arr << c_time_v

      c_time = c_time.advance(step)
    end

    return arr
  end


  class << self 
    def build(range)
      self.new(range.begin, range.end, range.exclude_end?)
    end
  end

end

# Convenience method
def RailsDateRange(range, step, &blk)
  r = RailsDateRange.build(range)

  r.every(step, &blk)
end

