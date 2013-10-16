
require 'spec_helper'

describe '.factory_build_for_store' do 

  before(:each) do 
    @record = MusicRecord.create t_id: "Alpha", genre: "Quiet"
    @data_object = {id: "Alpha", genre: "Loud", published_at: "2009-10-29", quantity: 12, price: 4.42, 
      an_unused_attribute: "N/A" }
    @identifier_hash =   {t_id: @data_object[:id] }
    @atts_hash = @data_object.reject{|k,v| k == :an_unused_attribute || k == :id}
  end  


  describe 'first argument: attributes_hash' do 
    it 'should be the only required parameter' do 
      rec = MusicRecord.factory_build_for_store(@atts_hash.merge(t_id: 'ZZZ'))

      expect(rec).to be_new_record
    end
  end

  describe 'second argument: identifier_hash' do 
    it 'should update existing object if identifier_hash meets conditions' do 
      rec = MusicRecord.factory_build_for_store(@atts_hash, @identifier_hash)

      expect(rec).to eq @record
      expect(rec).to be_changed
    end

    context "when .build_a_blob is defined for the class" do
      it 'should NOT create a blob' do 
        pending "Not needed. Blob will be kept in separate gem"
        rec = MusicRecord.factory_build_for_store(@atts_hash, @identifier_hash)
        expect(rec.contents).to be_nil
      end
    end
  end

  describe 'third argument, the full data object' do 
    describe 'block yielding' do 
      it "should yield new object and full_data_object" do 
        expect{|blk| MusicRecord.factory_build_for_store(@atts_hash, {}, @data_object, &blk) }.to yield_with_args(MusicRecord, @data_object)

      end
    end
  end


 # Note: NOT NEEDED, will remove  - Dan, 10/16

  describe 'third parameter :full_object' do 
    context "when .build_a_blob is defined for the class" do
      it 'should create an associated blob' do 
              pending "This is not needed: keep ActiveRecordCOntentBlob in its own place"


        rec = MusicRecord.factory_build_for_store(@atts_hash, @identifier_hash)
        rec.save 

        expect(ContentBlob.count).to eq 1
        expect(rec.contents).to eq @data_object
      end
    end
  end

end
