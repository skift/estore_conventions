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

    included do 
      class_attribute :archived_time_attribute
      self.archived_time_attribute = :rails_updated_at
    end

    ## can be overridden
    def archives
      @_thearchives ||= get_archives
    end


    def get_archives 
      arr = self.versions.updates.map do |v|
        obj = PaperTrail.serializer.load v.object

        Hashie::Mash.new(obj)
      end
      # throw in current record
      arr << self

      return arr
    end
    

    def archived_time_attribute
      self.class.archived_time_attribute
    end

    # a convenience method  
    # takes in an obj that has :rails_updated_at, either a EstoreConventional record
    #  or a Hashie::Mash
    #
    # returns a String in YYYY-MM-DD format
    # awkward construction (acts on an object, rather than takes a message) is because
    # hashie object may be involved...
    def archived_date_str(obj=nil) 
      if obj 
        if d = obj.send( archived_time_attribute)
          return d.strftime('%Y-%m-%d')
        end
      else
        # assume acting on self
        return self.send(archived_time_attribute).strftime('%Y-%m-%d')
      end
    end



    def archived_attribute_base(attribute, start_time = DEFAULT_DAYS_START.ago, end_time = DEFAULT_DAYS_END.ago, &blk )

      

      arr = self.archives

      start_time ||= arr.first.send archived_time_attribute
      end_time ||= arr.last.send archived_time_attribute

      time_frame = (start_time.beginning_of_day)..end_time

      # TODO: Make this more efficient
      # should just bring in as few as values as possible


#      arr.keep_if{|x| time_frame.cover?(x.rails_updated_at) }

      # transform reify objects into hash of {date => value}
      # obj is either Hashie::Mash or Record

      rblk =  block_given? ? blk : ->(hsh, obj){
        hsh[archived_date_str(obj)] = obj.send(attribute)
        
        hsh
      }


      att_hash = arr.reduce({}){ |hsh, obj|  
        rblk.call( hsh, obj)
      }


      return att_hash
    end


    # temp method, for prototyping
    def archive_attributes_utc(attribute,start_time = DEFAULT_DAYS_START.ago, end_time = DEFAULT_DAYS_END.ago)
      archived_attribute_base(attribute, start_time, end_time) do |hsh, obj|
        hsh[obj.send(archived_time_attribute).to_i] = obj.send(attribute)

        hsh
      end
    end

    # temp method, for prototyping
    # save as above, except the keys are Time objects
    def archive_attributes_by_time(attribute,start_time = DEFAULT_DAYS_START.ago, end_time = DEFAULT_DAYS_END.ago)
      archived_attribute_base(attribute, start_time, end_time) do |hsh, obj|
        hsh[obj.send(archived_time_attribute)] = obj.send(attribute)

        hsh
      end
    end



    ## TO BE DEPRECATED SOON
    # returns a Hash, with days as the keys: {'2013-10-12' => 100}
    def archived_attribute(*args)
      archived_attribute_by_day(*args)
    end
    


# NO

    # def archived_attribute_with_filled_days(attribute, start_time = DEFAULT_DAYS_START.ago, end_time = DEFAULT_DAYS_END.ago)

    #   hsh = archived_attribute(attribute, start_time, end_time)
    #   # if start_time or end_time is nil, then we have to set them to what hsh found
    #   unless hsh.empty? # unconfident code?
    #     start_time = Time.parse hsh.keys.first if start_time.nil?
    #     end_time = Time.parse hsh.keys.last if end_time.nil?
    #   end
    #   nhsh = {}
            
    #   # contains the entire date range, as the archived_attribute may be missing some days
    #   RailsDateRange(start_time..end_time, {days: 1}) do |val|
    #     day_val = val.strftime '%Y-%m-%d'

    #     nhsh[day_val] = hsh[day_val]
    #   end

    #   return nhsh
    # end


    def archived_attribute_by_day(attribute,start_time = DEFAULT_DAYS_START.ago, end_time = DEFAULT_DAYS_END.ago)
      #     hsh = archive_attributes_utc(attribute, start_time, end_time)
      hsh = archive_attributes_utc(attribute, nil, nil)
      # NOTE: hsh essentially contains EVERYTHING so that we can interpolate

      # remove any nil values
      hsh.delete_if{ |k, v| k.nil? || v.nil?}

      ## This is where we limit what's actually returned
      time_x = Time.at( [start_time.to_i, hsh.keys.first.to_i].max).beginning_of_day 
      time_y = Time.at( [(end_time || Time.now).to_i , hsh.keys.last.to_i].min    ).beginning_of_day 
      time_range = time_x..time_y

      days = RailsDateRange(time_range, {days: 1})
      interpolation = Interpolate::Points.new(hsh)

      interpolated_arr = if block_given? 
        yield days, interpolation
      else
        days.map{|d| [Time.at(d).strftime('%Y-%m-%d'), interpolation.at(d.to_i) ] }
      end

      return Hash[interpolated_arr]
    end


    # returns a hash in which each value is a *delta* of values
    def archived_attribute_delta_by_day(attribute, start_time = DEFAULT_DAYS_START.ago, end_time = DEFAULT_DAYS_END.ago)
      archived_attribute_by_day(attribute, start_time, end_time) do |days, interpolation|
        days.map.with_index(1) do |d, i| 
          [Time.at(d).strftime('%Y-%m-%d'), interpolation.at(days[i].to_i) - interpolation.at(d.to_i) ] if days[i]
        end
      end
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


    module ClassMethods
      def archiver(estore_record)
        # given an estore_record, get its archives

      end
    end


  end
end