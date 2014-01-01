require 'spec_helper'


describe 'Enumerable extensions for STD' do
  
  context 'simple foo' do 
    before do
      @arr = [10, 10, 14, 10]
    end 

    it 'should have e_sum' do 
      expect(@arr.e_sum).to eq 44
    end

    it 'should have e_mean' do
      expect(@arr.e_mean).to eq 11
    end

    it 'should have sample_variance' do
      expect(@arr.sample_variance).to eq 4
    end

    it 'should have standard_deviation' do
      expect(@arr.standard_deviation).to eq 2
    end
  end


  describe '#outliers' do
    context 'with an array' do 
      before do
        @arr = [10, 10, 9, 11, 12, 10, 10, 9, 11, 8, 20]
      end 

      it 'should run with no arguments' do
        expect(@arr.outliers.count).to eq 1
      end

      it 'should return an array of Hashes' do
        expect(@arr.outliers).to be_a Array
      end

      describe 'the contents of each Hash returned' do
        before do
          @outlier = @arr.outliers.first
        end

        it 'should have :value' do
          expect(@outlier[:value]).to eq 20
        end

        it 'should have :sigma' do
          expect(@outlier[:sigma] > 2.0).to be_true
        end
      end
    end

    context 'with a Hash' do
      before do
        @hsh = {a: 10, b: 10, c: 10, d: 10, e: 10, f: 40, g: 40, h: 10, i: 10, j: 10, k: 10}
        @outliers = @hsh.outliers
      end 

      it 'should return a Hash' do        
        expect(@outliers).to be_a Hash
      end

      it 'should have these expected results' do
        arr = @outliers.to_a
        expect(arr[0]).to eq [:f, {value:40, sigma: 2.0225995873897262}]
        expect(arr[-1]).to eq [:g, {value:40, sigma: 2.0225995873897262}]
      end
    end


    context 'optional arguments' do
      before do
        @hsh = {a: 10, b: 10, c: 10, d: 10, e: 10, f: 40, g: 40, h: 10, i: 10, j: 10, k: 10}
      end

      it 'uses first arg to define sigma' do
        expect(@hsh.outliers(0.0).keys).to eq @hsh.keys

      end


    end
  end


end