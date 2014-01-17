require 'spec_helper'

def _sdate(timeval)
  timeval.strftime '%Y-%m-%d'
end

describe EstoreConventions::ArchivedOutliers do
   before{ PaperTrail.enabled = true } 
   after{ PaperTrail.enabled = false } 

  before do

    @total_days = 25
    Timecop.travel(@total_days.days.ago){ @record = MusicRecord.create t_id: "Alpha", quantity: 0, price: 1.00}

    (@total_days-4).times do |d|
      # steady increase of 10
      t = @total_days - d 
      Timecop.travel(t.days.ago){ @record.update_attributes(quantity: @record.quantity + 10)}
    end

    Timecop.travel(3.days.ago){ @record.update_attributes(quantity: @record.quantity + 10, price: 1.00)}
    Timecop.travel(2.days.ago){ @record.update_attributes(quantity: @record.quantity + 500, price: 1.00)}
  
    Timecop.travel(1.days.ago){ @record.update_attributes(quantity: @record.quantity + 300, price: 1.00)}
  end



  describe '#versions_endpoints' do
    it 'should return array of first and last date as Strings'  do
      expect(@record.versions_endpoints(:quantity)).to eq [_sdate(@total_days.days.ago), _sdate(1.days.ago)]
    end
  end


  describe '#versions_average_for_attribute' do
    context 'with absolute values' do
      it 'should return Float representing average' do
        # 20 * 10 + 300 + 500 = 1000
        expect(@record.versions_average_for_attribute(:price)).to eq 1.00
      end
    end

    context 'with delta values' do
      it 'should return Float representing average' do
        # 20 * 10 + 300 + 500 = 1000
        expect(@record.versions_average_for_attribute(:quantity, delta: true)).to be_within(1).of 42
      end
    end
  end


  describe '#versions_complete_data_for_attribute' do
    context 'with absolute values' do
      it 'should return all data points for given attribute' do
        hsh = @record.versions_complete_data_for_attribute(:price)
        expect(hsh.to_a.count).to eq 24 # weird
      end    
    end

    context 'with delta values' do
      it 'should return all data points for given attribute' do
        hsh = @record.versions_complete_data_for_attribute(:quantity, delta: true)
        expect(hsh.to_a.count).to eq 25 # TODO: fix
      end    
    end
  end

  describe '#versions_outliers_for_attribute' do
    context 'with absolute values' do
      it 'should return the expected outliers in Hash form' do
        expect(@record.versions_outliers_for_attribute(:price)).to be_empty
      end
    end

    context 'with delta values' do
      it 'should return the expected outliers in Hash form' do
        outliers = @record.versions_outliers_for_attribute(:quantity, delta: true).values
        expect(outliers.first[:value]).to eq 500
        expect(outliers.last[:value]).to eq 300
      end
    end

  end
end