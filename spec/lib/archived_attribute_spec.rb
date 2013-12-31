require 'spec_helper'

def _sdate(timeval)
  timeval.strftime '%Y-%m-%d'
end

module EstoreConventions
  describe 'ArchivedAttributes' do
    before do
      PaperTrail.enabled = true
    end

    after do 
      PaperTrail.enabled = false
    end

    context 'class basics', focus: true  do
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
            obj = Hashie::Mash.new(rails_updated_at: Time.now)
            expect(@record.archived_date_str(obj)).to eq obj.rails_updated_at.strftime '%Y-%m-%d'
          end

          it 'also accepts no argument, so will act on itself' do
            expect(@record.archived_date_str).to eq @record.rails_updated_at.strftime '%Y-%m-%d'
          end
        end
      end
    end



    describe '#archived_attribute', focus: true do
    
      context 'arguments' do
        before do
          @time_1 = 9.days.ago
          @time_2 = 7.days.ago

          Timecop.travel(@time_1) do
            @record = MusicRecord.create(t_id: 'B-FLOW', quantity: 900)    
          end

          Timecop.travel(@time_2) do
            @record.update_attributes(quantity: 700)
          end
        end

        describe 'first arg is attribute name' do
          it 'should return Hash of values for given attribute' do
            expect(@record.archived_attribute(:quantity)).to eq( 
              {
                _sdate(@time_1) => 900,
                _sdate(@time_2) => 700
              }
            )
          end        
        end

        describe 'second arg is start_time' do
          it 'should should limit the values returned' do
            expect(@record.archived_attribute(:quantity, @time_1 + 1.day )).to eq( 
              {
                _sdate(@time_2) => 700
              }
            )
          end        
        end

        describe 'third arg is the end_time' do
          it 'should should limit the values returned' do
            expect(@record.archived_attribute(:quantity, @time_1 - 1.day, @time_2 - 1.day)).to eq( 
              {
                _sdate(@time_1) => 900
              }
            )
          end        
        end
      end


      context 'no updates have yet been made' do
        it 'should return Hash with one value' do
          Timecop.travel(3.days.ago) do
            @x = MusicRecord.create(t_id: 'X-FLOW', quantity: 5)
          end

          expect(@x.archived_attribute(:quantity)).to eq( { @x.archived_date_str => 5 } )
        end
      end
    end


    describe '#archived_attribute_with_filled_days', focus: true do
      it 'creates a Hash with keys for all days in the range' do
        @record = MusicRecord.create(t_id: 'empty', quantity: 9)

        expect(@record.archived_attribute_with_filled_days(:quantity, 5.days.ago, 1.days.ago).count).to eq 5
      end
    end

    describe '#raw_archived_attribute_delta_by_day' do
      before do 
        Timecop.travel(10.days.ago) do
          @record = MusicRecord.create(t_id: 'X', quantity: 100)
        end
      end

      it 'should be empty if there are 0 updates' do      
        expect(@record.raw_archived_attribute_delta_by_day(:quantity)).to be_empty
      end

      context 'just two days for comparison sake' do
        before do
          @time_1 = 9.days.ago
          Timecop.travel(@time_1) do
            @record.update_attributes({quantity: 200})
          end
        end

        it 'should fill out empty days' do
          deltas = @record.raw_archived_attribute_delta_by_day(:quantity)
          expect(deltas).to include( { _sdate(@time_1) => 100} )
          expect(deltas.count).to eq ArchivedAttributes::DEFAULT_DAY_SPAN
        end

        context 'ten days, one more datapoint' do
          before do
            Timecop.travel(9.days.from_now) do
              @record.update_attributes({quantity: 300})
            end
          end

          it 'should only contain two non-zero datapoints' do
            @deltas = @record.raw_archived_attribute_delta_by_day(:quantity)
            expect(@deltas.to_a.reject{|a| a[1].nil?}.count).to eq 2
          end
        end

      end
    end



    describe '#archived_attribute_delta_by_day' do
      before do 
        Timecop.travel(10.days.ago) do
          @record = MusicRecord.create(t_id: 'X', quantity: 100)
        end
      end

      it 'should be empty if there are 0 updates' do      
        expect(@record.archived_attribute_delta_by_day(:quantity)).to be_empty
      end

      context 'just two days for comparison sake' do
        before do
          @time_1 = 9.days.ago
          Timecop.travel(@time_1) do
            @record.update_attributes({quantity: 200})
          end
        end

        it 'should fill out empty days' do
          deltas = @record.archived_attribute_delta_by_day(:quantity)
          expect(deltas).to include( { _sdate(@time_1) => 100} )
          expect(deltas.count).to eq ArchivedAttributes::DEFAULT_DAY_SPAN

        end

        context 'ten days, one more datapoint' do
          before do
            Timecop.travel(9.days.from_now) do
              @record.update_attributes({quantity: 300})
            end
          end

          it 'should only contain two non-zero datapoints' do
            @deltas = @record.archived_attribute_delta_by_day(:quantity)
            expect(@deltas.to_a.reject{|a| a[1].nil?}.count).to eq 2
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


end #module end