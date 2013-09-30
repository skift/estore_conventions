module EstoreConventions
  module Builder

    def self.build_from_object(klass, obj, attributes_hash)
      object = klass.where(:t_id => obj[:id]).first_or_initialize
      object.assign_attributes(attributes_hash)
      object
    end

  end
end