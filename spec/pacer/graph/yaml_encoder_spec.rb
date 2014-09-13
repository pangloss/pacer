require 'spec_helper'

describe Pacer::YamlEncoder do
  let(:original) do
    { :string => ' bob ',
      :symbol => :abba,
      :empty => '',
      :integer => 121,
      :float => 100.001,
      :time => Time.utc(1999, 11, 9, 9, 9, 1),
      :object => { :a => 1, 1 => :a },
      :set => Set[1, 2, 3],
      :nested_array => [1, 'a', [2]],
      :ok_string => 'string value'
    }
  end

  describe '#encode_property' do
    subject do
      pairs = original.map do |name, value|
        [name, Pacer::YamlEncoder.encode_property(value)]
      end
      Hash[pairs]
    end

    it { should_not equal(original) }

    specify 'string should be stripped' do
      subject[:string].should == 'bob'
    end

    specify 'empty string becomes nil' do
      subject[:empty].should be_nil
    end

    specify 'numbers should be javafied' do
      subject[:integer].should == 121.to_java(:long)
      subject[:float].should == 100.001
    end

    specify 'dates are custom to enable range queries' do
      subject[:time].should =~ /^ utcT \d/
    end

    specify 'everything else should be yaml' do
      subject[:nested_array].should == ' ' + YAML.dump(original[:nested_array])
    end
  end

  describe '#decode_property' do
    it 'should round-trip cleanly' do
      # remove values that get cleaned up when encoded
      original.delete :string
      original.delete :empty

      original.values.each do |value|
        encoded = Pacer::YamlEncoder.encode_property(value)
        decoded = Pacer::YamlEncoder.decode_property(encoded)
        decoded.should == value
      end
    end

    it 'should strip strings' do
      encoded = Pacer::YamlEncoder.encode_property(' a b c ')
      decoded = Pacer::YamlEncoder.decode_property(encoded)
      decoded.should == 'a b c'
    end

    it 'empty strings -> nil' do
      encoded = Pacer::YamlEncoder.encode_property(' ')
      decoded = Pacer::YamlEncoder.decode_property(encoded)
      decoded.should be_nil
    end
  end
end
