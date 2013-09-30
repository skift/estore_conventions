require 'aggtive_record'

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

  def timestamp_attributes_for_create
    super << :rails_created_at
  end

  def timestamp_attributes_for_update
    super << :rails_updated_at
  end

end