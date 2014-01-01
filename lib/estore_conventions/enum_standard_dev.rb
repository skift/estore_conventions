module Enumerable
  def e_sum
    self.inject(0){|accum, i| accum + i }
  end

  def e_mean
    self.e_sum/self.length.to_f
  end

  def sample_variance
    m = self.e_mean
    a_sum = self.inject(0){|a, i| a + (i - m)**2 }

    a_sum/(self.length - 1).to_f
  end

  def standard_deviation
    return Math.sqrt(self.sample_variance)
  end

  # returns:
  # [{value: 10, sigma: 2.1}]
  def outliers(min_sigma = 2.0, opts = {})
    if self.is_a?(Array)
      std = standard_deviation
      mean = e_mean
      return self.map{ |val|
        val_sig = (val - mean) / std
        if val_sig > min_sigma
          {value: val, sigma: val_sig}
        else
          nil
        end
      }.compact
    else # assume hash keys
      the_std = self.values.standard_deviation
      the_mean = self.values.e_mean

      return Hash[self.map{ |(k,val)| 
        val_sig = (val - the_mean) / the_std
        if val_sig > min_sigma
          [k, {value: val, sigma: val_sig}]
        else
          nil
        end
      }.compact]
    end


  end

end 