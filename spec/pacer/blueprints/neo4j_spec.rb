require 'spec_helper'

module NeoSpec
  class Person < Pacer::Wrappers::VertexWrapper
    def self.route_conditions
      { type: 'person' }
    end
  end

  class Frog < Pacer::Wrappers::VertexWrapper
    def self.route_conditions
      { frog: 'yes' }
    end
  end

  Run.neo4j :read_only do
    use_pacer_graphml_data :read_only

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

    describe 'indexed' do
      before do
        graph.create_key_index :type, :vertex
        graph.create_key_index :name, :vertex
      end

      describe Person do
        subject { graph.v(Person) }

        # sanity checks
        it { should be_a Pacer::Filter::LuceneFilter }
        its(:query) { should == 'type:"person"' }
        # This doesn't work because neo indices are out of sync before the transaction finalizes
        #its(:count) { should == 2 }

        its(:wrapper) { should == Person }
      end

      describe Frog do
        subject { graph.v(Frog) }

        # sanity checks
        it { should_not be_a Pacer::Filter::LuceneFilter }
        its(:count) { should == 0 }

        its(:wrapper) { should == Frog }
      end
    end
  end
end
