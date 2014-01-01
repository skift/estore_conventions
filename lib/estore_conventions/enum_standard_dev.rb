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
    the_values = self.is_a?(Hash) ? self.values : self
    the_std = the_values.standard_deviation
    the_mean = the_values.e_mean

    coll = self.map do |v|
      val,key = Array(v).reverse
      val_sig = ((val - the_mean) / the_std).abs
      
      if z = ( val_sig >= min_sigma ? {value: val, sigma: val_sig} : nil )
        z = [key, z] unless key.nil?
      end

      z
    end
    coll = coll.compact

    return self.is_a?(Hash) ? Hash[coll] : coll
  end

end 