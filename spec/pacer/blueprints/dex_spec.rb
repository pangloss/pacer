require 'spec_helper'

Run.dex do
    use_simple_graph_data

    describe '#indices' do
      subject { graph.indices.to_a }
      it { should be_empty }
    end

    describe '#sanitize_properties' do
      let(:original) do
        { :string => ' bob ',
          :symbol => :abba,
          :empty => '',
          :integer => 121,
          :float => 100.001,
          :time => Time.utc(1999, 11, 9, 9, 9, 1),
          :object => { :a => 1, 1 => :a },
          99 => 'numeric key',
          'string key' => 'string value'
        }
      end

      subject { graph.sanitize_properties original }

      it { should_not equal(original) }
      specify 'original should be unchanged' do
        original.should == {
          :string => ' bob ',
          :symbol => :abba,
          :empty => '',
          :integer => 121,
          :float => 100.001,
          :time => Time.utc(1999, 11, 9, 9, 9, 1),
          :object => { :a => 1, 1 => :a },
          99 => 'numeric key',
          'string key' => 'string value'
        }
      end

      specify 'string should be stripped' do
        subject[:string].should == 'bob'
      end

      specify 'empty string becomes nil' do
        subject[:empty].should be_nil
      end

      specify 'numbers should be javafied' do
        subject[:integer].should == 121.to_java(:int)
        subject[:float].should == 100.001
      end

      specify 'everything else should be yaml' do
        subject[:time].should == YAML.dump(Time.utc(1999, 11, 9, 9, 9, 1))
      end

      its(:keys) { should == original.keys }
    end
end
