require 'spec_helper'

Run.tg(:read_only) do
  use_pacer_graphml_data :read_only

  describe Pacer::Filter::EmptyFilter do
    let(:origin) { graph.v(Tackle::SimpleMixin) }
    subject { Pacer::Route.empty(origin) }

    its(:graph) { should == graph }
    its(:element_type) { should == graph.element_type(:vertex) }
    its(:extensions) { should == [Tackle::SimpleMixin] }
    its(:build_pipeline) { should be_nil }

    context 'with route built on it' do
      subject { Pacer::Route.empty(origin).filter(name: 'joe') }
      its(:graph) { should == graph }
      its(:element_type) { should == graph.element_type(:vertex) }
      its(:extensions) { should == [Tackle::SimpleMixin] }
      its(:inspect) { should == '#<V -> V-Property(name=="joe")>' }
      it 'should create a pipeline with only the pipe added to it' do
        start_pipe, end_pipe = subject.send :build_pipeline
        start_pipe.should == end_pipe
        start_pipe.should be_a Java::ComTinkerpopPipesFilter::PropertyFilterPipe
      end
    end
  end
end
