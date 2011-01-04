require 'spec_helper'

for_neo4j do
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
        it { should == com.tinkerpop.blueprints.pgm.impls.neo4j.Neo4jVertex }
      end

      context 'a vertex' do
        subject { graph.element_type(v0) }
        it { should == com.tinkerpop.blueprints.pgm.impls.neo4j.Neo4jVertex }
      end

      context ':edge' do
        subject { graph.element_type(:edge) }
        it { should == com.tinkerpop.blueprints.pgm.impls.neo4j.Neo4jEdge }
      end

      context 'an edge' do
        subject { graph.element_type(e0) }
        it { should == com.tinkerpop.blueprints.pgm.impls.neo4j.Neo4jEdge }
      end
    end

    describe '#indices' do
      subject { graph.indices.to_a }
      its(:count) { should == 2 }
    end
  end
end
