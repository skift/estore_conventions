require 'spec_helper'

describe 'archived_attribute methods' do

  context 'class basics' do
    before(:each) do 
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
  end



  describe '#archived_attribute' do
    context 'arguments' do
      describe 'first arg is attribute name' do
        it 'should return Hash of values for given attribute' do
          pending
          expect(@record.archived_attribute(:quantity)).to eq( { })
        end
      end
    end
  end


  describe '#archived_attribute_delta_by_day' do
    before do 
      @record = MusicRecord.create(t_id: 'X', quantity: 100)
    end

    context 'one day' do
      before do
        Timecop.travel(1.day.from_now)
        @record.update_attributes({quantity: 200})
        Timecop.travel(1.day.from_now)
      end

      it 'should calculate the average change between days' do
        expect(@record.archived_attribute_delta_by_day(:quantity)).to eq {100}
      end

      context 'ten days, one more datapoint' do
        before do
          Timecop.travel(9.days.from_now)
          @record.update_attributes({quantity: 300})
          Timecop.travel(1.day.from_now)
        end

        it 'should only contain two datapoints' do
          @deltas = @record.archived_attribute_delta_by_day(:quantity)
          expect(@deltas.to_a.count).to eq 2
        end
      end

    end
  end



  describe '#historical_rate_per_day' do
    before do 
      @record = MusicRecord.create(t_id: 'X', quantity: 100)
    end

    context 'just one day' do
      it 'should return 0' do
        expect(@record.historical_rate_per_day).to eq 0
      end

      it 'should return nil to indicate not enough data?'
    end

    context 'two days' do
      before do
        Timecop.travel(1.day.from_now)  
        @record.update_attributes({quantity: 200})
        Timecop.travel(1.day.from_now)
      end

      it 'should calculate the average change between days' do
        expect(@record.historical_rate_per_day(:quantity)).to eq 100
      end

      context '10 days' do
        before do
          Timecop.travel(9.days.from_now)  
          @record.update_attributes({quantity: 300})
          Timecop.travel(1.day.from_now)
        end


        it 'should calculate the average between beginning and end' do
          pending
        end
      end

    end
  end
end