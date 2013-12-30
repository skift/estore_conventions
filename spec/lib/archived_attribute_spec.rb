require 'spec_helper'

describe 'archived_attribute methods' do
  before do
    PaperTrail.enabled = true
  end

  after do 
    PaperTrail.enabled = false
  end

  context 'class basics'  do
    context 'basic paper_trail implementation' do
      before do 
        @record = MusicRecord.create(t_id: 'AB', quantity: 100)
      end

      it 'should not create new versions if no changes were made' do
        @record.save
        expect(@record.versions.updates.count).to eq 0  
      end


      it 'should save versions with each save' do 
        @record.update_attributes(:quantity => 200)
        expect(@record.versions.updates.count).to eq 1    

        @record.quantity = 100
        @record.save
        expect(@record.versions.updates.count).to eq 2
      end


      describe '#archived_date_str' do
        it 'is a convenience method for date printing based on :rails_updated_at' do
          expect(@record.archived_date_str).to eq @record.rails_updated_at.strftime '%Y-%m-%d'
        end
      end
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