require 'spec_helper'

describe '.add_sorted_value_and_sort' do 
  context "Augmentation of sorted_values" do 

    before(:each) do 
      MusicRecord.create(t_id: 'A', price: 10.20, quantity: 100)
      MusicRecord.create(t_id: 'B', price: 2.20, quantity: 9)
    end


    context 'a normal column based sort' do 
      before(:each) do 
        @sorted_list = MusicRecord.add_sorted_value_and_sort(:quantity)
      end

      it 'should return a ActiveRecord::Relation' do 
        expect(@sorted_list).to be_a ActiveRecord::Relation
      end

      it 'should sort descending by default' do 
        expect(@sorted_list.first.quantity).to eq 100
      end
    end

    context '@sorted_value ad-hoc attribute' do
      before(:each) do 
        @sorted_list = MusicRecord.add_sorted_value_and_sort(:quantity)
      end

      it 'should add @sorted_value to each member' do 
        expect(@sorted_list.first.sorted_value).to eq 100
      end
    end



  end
end