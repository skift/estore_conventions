require 'paper_trail'
require 'hashie'

module EstoreConventions
  module ArchivedAttributes
    extend ActiveSupport::Concern

    DEFAULT_NUM_DAYS_START = 30
    DEFAULT_NUM_DAYS_END = 1

    DEFAULT_DAY_SPAN = (DEFAULT_NUM_DAYS_START - DEFAULT_NUM_DAYS_END) + 1
    
    DEFAULT_DAYS_START = DEFAULT_NUM_DAYS_START.days
    DEFAULT_DAYS_END = DEFAULT_NUM_DAYS_END.day

    # a convenience method  
    # takes in an obj that has :rails_updated_at, either a EstoreConventional record
    #  or a Hashie::Mash
    #
    # returns a String in YYYY-MM-DD format
    # awkward construction (acts on an object, rather than takes a message) is because
    # hashie object may be involved...
    def archived_date_str(obj=nil) 
      if obj 
        if d = obj.rails_updated_at
          return d.strftime('%Y-%m-%d')
        end
      else
        # assume acting on self
        return self.rails_updated_at.strftime('%Y-%m-%d')
      end
    end

    # returns a Hash, with days as the keys: {'2013-10-12' => 100}
    def archived_attribute(attribute, start_time = DEFAULT_DAYS_START.ago, end_time = DEFAULT_DAYS_END.ago )

      time_frame = (start_time.beginning_of_day)..end_time

      arr = self.versions.updates.map do |v| 
        obj = PaperTrail.serializer.load v.object 

        Hashie::Mash.new(obj)
      end

      # throw in most recent record
      arr << self

      # weed out old entries
      arr.keep_if{|x| time_frame.cover?(x.rails_updated_at) }

      # transform reify objects into hash of {date => value}
      # obj is either Hashie::Mash or Record
      return arr.reduce({}) do |hsh, obj|
        hsh[archived_date_str(obj)] = obj.send(attribute)
        
        hsh
      end
    end



    def archived_attribute_with_filled_days(attribute, start_time = DEFAULT_DAYS_START.ago, end_time = DEFAULT_DAYS_END.ago)

      hsh = archived_attribute(attribute, start_time, end_time)
      nhsh = {}
            
      # contains the entire date range, as the archived_attribute may be missing some days
      RailsDateRange(start_time..end_time, {days: 1}) do |val|
        day_val = val.strftime '%Y-%m-%d'

        nhsh[day_val] = hsh[day_val]
      end

      return nhsh
    end



    # not tested
    # very convoluted method that tries to do some extrapolation for missing days
    # returns a hash in which each value is a *delta* of values
    def archived_attribute_delta_by_day(attribute, start_time = DEFAULT_DAYS_START.ago, end_time = DEFAULT_DAYS_END.ago)
          
      hsh = archived_attribute_with_filled_days(attribute, start_time, end_time)

      ## now lets iterate and build a new Hash with interpolated values

      prev_valid_val = nil
      nil_vals = []

      interpolated_hash = hsh.inject({}) do |nhash, (k,v)|
        nhash[k] = nil
        nil_vals << k

        if v.present?          
          if prev_valid_val.present?
            # endpoint found
            # calculate values
            c = nil_vals.count
            delta = (v - prev_valid_val) / c.to_f
            # interpolate

            while q = nil_vals.shift
              puts "Shifted: #{q} and set equal to #{delta}"
              nhash[q] = delta
            end
          end

          prev_valid_val = v
        end         

        nhash
      end

      return interpolated_hash

    end

    # UNTESTED
    # returns a scalar (Float)
    #   
    #
    def historical_rate_per_day(attribute, start_time = DEFAULT_DAYS_START.ago, end_time = DEFAULT_DAYS_END.ago)
      arr = archived_attribute(attribute, start_time, end_time).to_a
      # find first entry that has a number
      first_day, xval = arr.find{|v| v[1].is_a?(Numeric)} 
      # find last entry that has a number
      last_day, yval = arr.reverse.find{|v| v[1].is_a?(Numeric)} 

      first_day = Time.parse(first_day).beginning_of_day rescue nil
      last_day = Time.parse(last_day).beginning_of_day rescue nil

      return nil if first_day.nil? || last_day.nil?

      day_count = (last_day - first_day) / ( 60 * 60 * 24).to_f
      diff = yval - xval

      day_span = day_count

      if day_span > 0
        rate = diff.to_f / day_span
      else
        rate = 0
      end

      return rate
    end


  end
end