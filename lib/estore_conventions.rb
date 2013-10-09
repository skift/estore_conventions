require 'aggtive_record'
require 'acts-as-taggable-on'
ActsAsTaggableOn.force_lowercase = true


module EstoreConventions     
  extend ActiveSupport::Concern
  include AggtiveRecord::Aggable

  included do
    validates_presence_of :t_id
    validates_uniqueness_of :t_id
  end


  module ClassMethods

    def add_sorted_value_and_sort(foo, opts={})

      if foo.class == Proc 
        self.all.sort_by do |channel| 
          val = foo.call(channel) 
          channel.instance_eval "def sorted_value; #{val}; end"

          -val            
        end
      elsif foo.class == String || foo.class == Symbol
        order_val = opts[:order] || 'DESC'
        self.order("#{foo} #{order_val}").
              select("#{self.table_name}.*, #{self.table_name}.#{foo} AS sorted_value").
              limit(opts[:limit])
      else  
        raise ArgumentError, "#{foo} needs to be a String, Symbol, or Proc"        
      end
    end

  end

  module InstanceMethods
    def archived_attribute(attribute, time_frame=(30.days))
      # normalize time since we are returning today as a whole day
      time_frame = (DateTime.now + 1.day).beginning_of_day - time_frame

      # transform papertrail objects to reify objects
      a = self.versions.map {|v| v.reify }

      # get rid of nil first version
      a.compact!

      # add the current object to the array
      a << self

      # weed out old entries
      a.delete_if {|x| x.rails_updated_at <= time_frame }

      # sort hash based on key  
      a.sort_by!{|x| x.rails_updated_at }

      # transform reify objects into hash of {date => value}
      a.reduce({}) do |hsh,val|
        hsh[val.rails_updated_at.strftime('%Y-%m-%d')] = val.send(attribute)
        hsh
      end
    end
  end

  def timestamp_attributes_for_create
    super << :rails_created_at
  end

  def timestamp_attributes_for_update
    super << :rails_updated_at
  end

end

require_relative 'estore_conventions/builder'