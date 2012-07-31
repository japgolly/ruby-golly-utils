# encoding: utf-8
require_relative '../../../bootstrap/spec'
require 'golly-utils/testing/rspec/arrays'

describe 'RSpec array matchers' do

  context '#equal_array' do
    it("should pass when arrays match exactly"){
      %w[a b c].should equal_array %w[a b c]
    }

    it("should fail when arrays differ"){
      [
        %w[x b c],
        %w[b c],
        %w[a b],
        %w[a b c x],
      ].each do |v|
        expect{ %w[a b c].should equal_array v }.to raise_error /Missing|Unexpected/
      end
    }

    it("should require matching amounts of duplicate elements"){
      %w[a a b].should equal_array %w[a a b]
      expect{ %w[a b].should equal_array %w[a a b] }.to raise_error /freq/
      expect{ %w[a b b].should equal_array %w[a a b] }.to raise_error /freq/
    }

    it("should require arrays to be ordered the same"){
      expect{ %w[a b].should equal_array %w[b a] }.to raise_error /order/
    }
  end
end
