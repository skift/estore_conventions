require 'spec_helper'

describe 'archived_attribute methods' do

  before do 
    @record = MusicRecord.create(t_id: 'A', price: 10.20, quantity: 100)
  end

  context 'basic paper_trail implementation' do
    it 'should save versions with each save' do 
      @record.quantity = 200
      @record.save
      expect(@record.versions.updates.count).to eq 1    

      @record.quantity = 100
      @record.save
      expect(@record.versions.updates.count).to eq 2
    end

    it 'should not create new versions if no changes were made' do
      @record.save
      expect(@record.versions.updates.count).to eq 0  
    end
  end

  describe '#archived_date_str' do
    it 'is a convenience method for date printing based on :rails_updated_at' do
      expect(@record.archived_date_str).to eq @record.rails_updated_at.strftime '%Y-%m-%d'
    end
  end


  describe '#archived_attribute' do
    before do 
      @record = MusicRecord.create(t_id: 'B-FLOW', price: 10.20, quantity: 100)
      @record.quantity = 200
      @record.save
    end

    context 'arguments' do
      describe 'first arg is attribute name' do
        it 'should return Hash of values for given attribute' do
          pending 'confirmation that we really do want a value if no updates have been made'
          expect(@record.archived_attribute(:quantity)).to eq( {@record.archived_date_str => 100})
        end

        context 'no updates have yet been made' do
          it 'should return Hash of values for given attribute' do
            pending 'confirmation that we really do want a value if no updates have been made'
            x = MusicRecord.create(t_id: 'X-FLOW', quantity: 100)
            expect(x.archived_attribute(:quantity)).to eq( {x.archived_date_str => 100})
          end
        end
      end

    end
  end


end