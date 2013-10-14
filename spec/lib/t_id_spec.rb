require 'spec_helper'


describe 't_id convention' do 

  # only necessary for setting custom t_ids

  it 'should by default have t_id_attribute set to :t_id'


  describe 'getter/setter class_attribute' do 
    after(:each) do 
      MusicRecord.attr_t_id :t_id
    end

    it 'should be able to set its :t_id_attribute' do 
      expect(MusicRecord.t_id_attribute).to eq :t_id

      MusicRecord.attr_t_id :title
      expect(MusicRecord.t_id_attribute).to eq :title
    end

    it 'should raise an error if the specified attribute doesnt exist' do 
      expect{MusicRecord.attr_t_id :not_an_att}.to raise_error ArgumentError
    end
  end


  describe 'enforcement of validation' do 
    before(:each) do 
      @record = MusicRecord.create(t_id: "Hey")
    end

    after(:each) do 
      MusicRecord.attr_t_id :t_id
    end


    context 'validation rules' do 
      it 'should validate uniqueness of' do 
        MusicRecord.create(t_id: "Hey")
        expect(MusicRecord.count).to eq 1
      end
    end

    context 'validation of new t_id attribute' do 
      it 'should honor t_id changed ad-hoc' do 
        pending "This fails because we don't have validation dynamically set"
        MusicRecord.attr_t_id :title
        MusicRecord.create(t_id: "Hey", title: "i'm different")
        expect(MusicRecord.count).to eq 2
      end
    end



  end
end