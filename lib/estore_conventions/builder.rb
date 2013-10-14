module EstoreConventions
  module Builder

    # expects: class has a .find_or_init_by_t_id
    # klass is a class name, like MusicRecord
    # data_object is an API-sourced thing that contains someting to extract a t_id from
    # attributes_hash are the model specific attributes to *assign*

    # Returns: an instantiation of a new or existing record with new attributes assigned
    def self.build_from_object(klass, data_object, attributes_hash)      
      record = klass.find_or_init_by_t_id(data_object[:id]) # code smell
                                                    # we don't ALWAYS know :id contains t_id
      merged_atts_hash = merge_data_object_with_record(attributes_hash, record)
      record.assign_attributes(merged_atts_hash)

      record
    end


    # a helper method that will take an object's attributes and merge it with 
    # new values from an incoming Hash
    #
    # unlike build form object, it does not return an object

    def self.merge_data_object_with_record(atts_hash, record_atts={})
      # convenience if dealing with activerecord
      d =  (record_atts.respond_to?(:attributes) ? record_atts.attributes : record_atts).symbolize_keys

      return d.merge(atts_hash)
    end

  end
end