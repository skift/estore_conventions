module Enumerable
  def e_sum
    col = self.is_a?(Hash) ? self.values : self

    col.inject(0){|accum, i| accum + i }
  end

  def e_mean
    self.e_sum/self.length.to_f
  end

  def sample_variance
    col = self.is_a?(Hash) ? self.values : self

    a_sum = col.inject(0){|a, i| a + (i - self.e_mean)**2 }

    a_sum/(self.length - 1).to_f
  end

  def standard_deviation
    return Math.sqrt(self.sample_variance)
  end

  # returns:
  #  if Array: [{value: 10, sigma: 2.1}]
  #  if Hash: {key: {value: 10, sigma: 2.1}}
  #
  # args:
  #  min_sigma(Float) - minimum number of standard deviations (>=)
  #  opts(Hash) - not currently used

  def outliers(min_sigma = 2.0, opts = {})
    the_std = self.standard_deviation
    the_mean = self.e_mean

    coll = self.map do |v|
      val, key = Array(v).reverse
      val_sigma = ((val - the_mean) / the_std)
      # if val_sigma passes threshold, then create a Hash, else, return nil
      if z = ( val_sigma.abs >= min_sigma.abs ? {value: val, sigma: val_sigma} : nil )
      # if key is not nil? (i.e. self is a Hash), wrap it in an Array
        z = [key, z] unless key.nil?
      end

      z
    end
    coll = coll.compact

    return self.is_a?(Hash) ? Hash[coll] : coll
  end

end 