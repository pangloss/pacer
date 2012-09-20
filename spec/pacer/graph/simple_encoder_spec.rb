require 'spec_helper'

Run.tg do
  describe Pacer::SimpleEncoder do
    use_simple_graph_data

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
          [name, Pacer::SimpleEncoder.encode_property(value)]
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

      it 'should not change anything else' do
        # remove values that get cleaned up when encoded
        original.delete :string
        original.delete :empty

        original.values.each do |value|
          encoded = Pacer::SimpleEncoder.encode_property(value)
          encoded.should == value
        end
      end

    end

    describe '#decode_property' do
      it 'should round-trip cleanly' do
        # remove values that get cleaned up when encoded
        original.delete :string
        original.delete :empty

        original.values.each do |value|
          encoded = Pacer::SimpleEncoder.encode_property(value)
          decoded = Pacer::SimpleEncoder.decode_property(encoded)
          decoded.should == value
        end
      end

      it 'should strip strings' do
        encoded = Pacer::SimpleEncoder.encode_property(' a b c ')
        decoded = Pacer::SimpleEncoder.decode_property(encoded)
        decoded.should == 'a b c'
      end

      it 'empty strings -> nil' do
        encoded = Pacer::SimpleEncoder.encode_property(' ')
        decoded = Pacer::SimpleEncoder.decode_property(encoded)
        decoded.should be_nil
      end
    end
  end
end
