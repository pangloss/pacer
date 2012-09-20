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
end
