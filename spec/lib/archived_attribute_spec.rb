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
            obj = Hashie::Mash.new(rails_updated_at: Time.now)
            expect(@record.archived_date_str(obj)).to eq obj.rails_updated_at.strftime '%Y-%m-%d'
          end

          it 'also accepts no argument, so will act on itself' do
            expect(@record.archived_date_str).to eq @record.rails_updated_at.strftime '%Y-%m-%d'
          end
        end
      end
    end



    describe '#archived_attribute' do
    
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

      context 'bounds' do 
        before do
          Timecop.travel(1000.days.ago){
            @record = MusicRecord.create(t_id: 'ZZZ1', quantity: 10)    
          }
          Timecop.travel(20.days.ago){ @record.update_attributes(quantity: 20) }
          Timecop.travel(5.days.ago){ @record.update_attributes(quantity: 40) }
          @record.update_attributes(quantity: 140)
        end

        it 'should include all versions if both time args are nil' do
          expect(@record.archived_attribute(:quantity, nil, nil).count).to eq 4
        end

        it 'should include all past if first time args is nil' do
          outliers = @record.archived_attribute(:quantity, nil)
          expect(outliers.count).to eq 3
          expect(outliers.to_a.first[1]).to eq 10
           expect(outliers.to_a.last[1]).to eq 40
        end

        it 'should include records up to now if second time args is nil' do
          outliers = @record.archived_attribute(:quantity, 30.days.ago, nil)
          expect(outliers.count).to eq 3
          expect(outliers.to_a.first[1]).to eq 20
          expect(outliers.to_a.last[1]).to eq 140
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


    describe '#archived_attribute_with_filled_days' do
      it 'creates a Hash with keys for all days in the range' do
        @record = MusicRecord.create(t_id: 'zzz', quantity: 9)

        expect(@record.archived_attribute_with_filled_days(:quantity, 5.days.ago, 1.days.ago).count).to eq 5
      end
    end


    describe '#archived_attribute_delta_by_day' do
  
      it 'should still have full key count if there are 0 updates' do  
        @record = MusicRecord.create(t_id: 'X', quantity: 100)    
        expect(@record.archived_attribute_delta_by_day(:quantity).keys.count).to eq ArchivedAttributes::DEFAULT_DAY_SPAN
      end


      context 'just two days for comparison sake' do
        before do            
          @time_1 = 5.days.ago
          @time_2 = 1.days.ago
          Timecop.travel(@time_1){
            @record = MusicRecord.create(t_id: 'X2', quantity: 0)
          }
          Timecop.travel(@time_2){
            @record.update_attributes(quantity: 3000)
          }            

        end

        it 'should interpolate between spans of more than one day' do
          deltas = @record.archived_attribute_delta_by_day(:quantity, @time_1, 1.days.ago)
          # this produces 5 days worth of values, so split of 20 across, as 3000/5 = 600
          # yes, it is convoluted
          expect(deltas.values.select{|v| v == 600}.count).to eq 5
        end

        it 'should interpolate across ALL days, even prior to first starting val' do
          deltas = @record.archived_attribute_delta_by_day(:quantity, 30.days.ago, 1.day.ago)
          expect(deltas.values.select{|v| v == 100}.count).to eq 30
        end

        it 'should not fill in values AFTER the last valid val' do
          Timecop.travel(10.days.from_now) do 
            deltas = @record.archived_attribute_delta_by_day(:quantity, 30.days.ago, 1.day.ago)
            expect(deltas.values.select{|v| v.nil?}.count).to eq 10
            expect(deltas.values.reject{|v| v.nil?}.count).to eq 20
          end
        end
       
      end
    end



    describe '#historical_rate_per_day'  do
      before do 

        Timecop.travel(11.days.ago){ @record = MusicRecord.create(t_id: 'X', quantity: 200) }
      end

      context 'just one day' do
        it 'should be nil' do
          expect(@record.historical_rate_per_day(:quantity)).to eq 0
        end

      end

      context 'two days' do
        before do
          Timecop.travel(1.days.ago){ @record.update_attributes({quantity: 100})  }            
        end

        it 'should calculate the average change between days' do
          expect(@record.historical_rate_per_day(:quantity)).to eq -10
        end

      end
    end
  end


end #module end