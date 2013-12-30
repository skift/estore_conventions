require 'aggtive_record'
require 'acts-as-taggable-on'
require_relative 'estore_conventions/archived_attributes'
require_relative 'estore_conventions/rails_date_range'

ActsAsTaggableOn.force_lowercase = true


module EstoreConventions     
  extend ActiveSupport::Concern
  include AggtiveRecord::Aggable
  include EstoreConventions::ArchivedAttributes


  included do
    class_attribute :t_id_attribute

    self.t_id_attribute = :t_id  # by default
    validates_presence_of self.t_id_attribute
    validates_uniqueness_of self.t_id_attribute

  end


  # instance methods

  module ClassMethods
    def find_or_init_by_t_id(tid)
       where(:t_id => tid).first_or_initialize
    end

    # atts_hash are the attributes to assign to the Record
    # identifier_conditions is what the scope for first_or_initialize is called upon
    #  so that an existing object is updated
    #  full_data_object is passed in to be saved as a blob
    def factory_build_for_store(atts_hash, identifier_conditions = {}, full_data_object={}, &blk)      
      if identifier_conditions.empty?
        record = self.new
      else
        record = self.where(identifier_conditions).first_or_initialize
      end
      record.assign_attributes(atts_hash, :without_protection => true)

      if block_given?
        yield record, full_data_object
      end

      return record
    end


    def attr_t_id(attname)
      puts "WARNING: Customizing t_id and proper validation is not supported yet"
      raise ArgumentError unless column_names.include?(attname.to_s)
      self.t_id_attribute = attname 
    end

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







  end ##### ClassMethods



  ############ InstanceMethods



  def timestamp_attributes_for_create
    super << :rails_created_at
  end

  def timestamp_attributes_for_update
    super << :rails_updated_at
  end

end

require_relative 'estore_conventions/builder'