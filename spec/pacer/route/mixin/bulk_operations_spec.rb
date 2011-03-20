require 'spec_helper'

for_neo4j do
  use_pacer_graphml_data

  describe RouteOperations do
    describe '#bulk_job' do
      context 'commit every 2nd record, updating all vertices' do
        context 'with wrapped elements' do
          it 'should update all records' do
            graph.v(Tackle::SimpleMixin).bulk_job(2) do |v|
              v[:updated] = 'yes'
            end
            graph.v(:updated => 'yes').count.should == 7
          end
        end
      end
    end
  end
end

