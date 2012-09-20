require 'spec_helper'

Run.neo4j do
    use_simple_graph_data

    describe '#vertex' do
      it 'should not raise an exception for invalid key type' do
        graph.vertex('bad id').should be_nil
      end
    end

    describe '#edge' do
      it 'should not raise an exception for invalid key type' do
        graph.edge('bad id').should be_nil
      end
    end

    describe '#indices' do
      subject { graph.indices.to_a }
      its(:count) { should == 0 }
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

      specify 'numbers should be unmodified' do
        subject[:integer].should == 121
        subject[:float].should == 100.001
      end

      specify 'everything else should be yaml' do
        subject[:time].should == YAML.dump(Time.utc(1999, 11, 9, 9, 9, 1))
      end

      its(:keys) { should == original.keys }
    end

    describe '#in_vertex' do
      it 'should wrap the vertex' do
        v = e0.in_vertex(Tackle::SimpleMixin)
        v.should == v1
        v.extensions.should include(Tackle::SimpleMixin)
      end

      it 'should wrap the vertex 2' do
        v = e0.in_vertex([Tackle::SimpleMixin])
        v.should == v1
        v.extensions.should include(Tackle::SimpleMixin)
      end
    end

    describe '#out_vertex' do
      it 'should wrap the vertex' do
        v = e0.out_vertex(Tackle::SimpleMixin)
        v.should == v0
        v.extensions.should include(Tackle::SimpleMixin)
      end

      it 'should wrap the vertex 2' do
        v = e0.out_vertex([Tackle::SimpleMixin])
        v.should == v0
        v.extensions.should include(Tackle::SimpleMixin)
      end
    end
  end
