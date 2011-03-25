require 'spec_helper'

for_each_graph do
  use_pacer_graphml_data

  describe RouteOperations, :transactions => false do
    before { setup_data }

    describe '#bulk_job', :transactions => false do
      context 'commit every 2nd record, updating all vertices' do
        context 'with wrapped elements' do
          it 'should update all records' do
            graph.v(Tackle::SimpleMixin).bulk_job(2) do |v|
              v[:updated] = 'yes'
            end
            graph.v(:updated => 'yes').count.should == 7
          end
        end

        it 'should update all records' do
          graph.v.bulk_job(2) do |v|
            v[:updated] = 'yup'
          end
          graph.v(:updated => 'yup').count.should == 7
        end
      end
    end
  end
end

