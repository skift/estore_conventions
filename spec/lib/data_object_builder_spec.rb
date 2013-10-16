require 'spec_helper'

include EstoreConventions::Builder
describe EstoreConventions::Builder do 

  before(:each) do 
    @record = MusicRecord.create t_id: "Alpha", genre: "Quiet"
    @data_object = {id: "Alpha", genre: "Loud", published_at: "2009-10-29", quantity: 12, price: 4.42, 
      an_unused_attribute: "N/A" }
    # note, Builder passes in both the original data object AND the derived attributes hash
    @attributes_hash = @data_object.reject{|k,v| k == :an_unused_attribute || k == :id}
  end

  let(:builder){ EstoreConventions::Builder }

  describe '.merge_data_object_with_record' do 
    context 'a helper method of sorts' do 
      it 'should accept a minimum of one argument: attributes_hash, and symbolize the keys' do 
        atts = builder.merge_data_object_with_record(@attributes_hash, {})
        expect(atts).to be_a Hash
        expect(atts.symbolize_keys).to eq @attributes_hash.symbolize_keys
      end

      context 'two arguments' do
        it 'should accept an ActiveRecord as second arg' do 
          atts =  builder.merge_data_object_with_record(@attributes_hash, @record)

          expect(atts[:id]).to eq @record.id
          expect(atts[:genre]).to eq "Loud" # comes from data_object
        end
      end
    end
  end

  describe '.build_from_object' do 
    it 'should return an instantiated but unsaved record' do 
      built_record = builder.build_from_object(MusicRecord, @data_object, @attributes_hash)
      
      expect(built_record).to eq @record
      expect(built_record).not_to be_new_record
      expect(built_record).to be_changed
    end

    it 'should instantiate new records if t_id doesnt already exist' do 
      new_atts = new_obj = {id: 'Beta', title: "A new work"}
      new_record = builder.build_from_object(MusicRecord, new_obj, new_atts)

      expect(new_record).to be_valid
      expect(new_record).to be_new_record
    end
  end


end

