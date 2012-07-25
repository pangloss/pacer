require 'spec_helper'

Run.neo4j do
  describe Pacer::Neo4jGraph do
    let(:v0) { graph.create_vertex }
    let(:v1) { graph.create_vertex }
    let(:e0) { graph.create_edge '0', v0, v1, :default }

    describe '#element_type' do
      context 'invalid' do
        it { expect { graph.element_type(:nothing) }.to raise_error(ArgumentError) }
      end

      context ':vertex' do
        subject { graph.element_type(:vertex) }
        it { should == com.tinkerpop.blueprints.impls.neo4j.Neo4jVertex }
      end

      context 'a vertex' do
        subject { graph.element_type(v0) }
        it { should == com.tinkerpop.blueprints.impls.neo4j.Neo4jVertex }
      end

      context ':edge' do
        subject { graph.element_type(:edge) }
        it { should == com.tinkerpop.blueprints.impls.neo4j.Neo4jEdge }
      end

      context 'an edge' do
        subject { graph.element_type(e0) }
        it { should == com.tinkerpop.blueprints.impls.neo4j.Neo4jEdge }
      end

      context ':mixed' do
        subject { graph.element_type(:mixed) }
        it { should == com.tinkerpop.blueprints.impls.neo4j.Neo4jElement }
      end

      context ':object' do
        subject { graph.element_type(:object) }
        it { should == Object }
      end

      context 'from element_type' do
        context ':vertex' do
          subject { graph.element_type(graph.element_type :vertex) }
          it { should == com.tinkerpop.blueprints.impls.neo4j.Neo4jVertex }
        end

        context ':edge' do
          subject { graph.element_type(graph.element_type :edge) }
          it { should == com.tinkerpop.blueprints.impls.neo4j.Neo4jEdge }
        end

        context ':mixed' do
          subject { graph.element_type(graph.element_type :mixed) }
          it { should == com.tinkerpop.blueprints.impls.neo4j.Neo4jElement }
        end

        context ':object' do
          subject { graph.element_type(graph.element_type :object) }
          it { should == Object }
        end
      end

      context 'from index_class' do
        context ':vertex' do
          subject { graph.element_type(graph.index_class :vertex) }
          it { should == com.tinkerpop.blueprints.impls.neo4j.Neo4jVertex }
        end

        context ':edge' do
          subject { graph.element_type(graph.index_class :edge) }
          it { should == com.tinkerpop.blueprints.impls.neo4j.Neo4jEdge }
        end
      end
    end

    describe '#indices' do
      subject { graph.indices.to_a }
      its(:count) { should == 2 }
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
end
