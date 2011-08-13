require 'spec_helper'

Run.all(:read_only) do
  use_pacer_graphml_data(:read_only)

  context Pacer::Core::Graph::VerticesRoute do
    subject { graph.v }
    it { should be_a Pacer::Core::Graph::VerticesRoute }
    its(:count) { should == 7 }

    describe '#out_e' do
      subject { graph.v.out_e }
      it { should be_a Pacer::Core::Graph::EdgesRoute }
      its(:count) { should == 14 }

      describe '(:uses)' do
        subject { graph.v.out_e(:uses) }
        its(:count) { should == 5 }
        it { subject.labels.to_a.should == ['uses'] * 5 }
      end

      describe '(:uses, :wrote)' do
        subject { graph.v.out_e(:uses, :wrote) }
        its(:count) { should == 9 }
        it { Set[*subject.labels].should == Set['uses', 'wrote'] }
      end
    end

    describe '#out' do
      subject { graph.v.out }
      it { should be_a Pacer::Core::Graph::VerticesRoute }
      its(:count) { should == 14 }
      its(:to_a) { should == graph.v.out_e.in_v.to_a }

      describe '(:uses, :wrote)' do
        subject { graph.v.out(:uses, :wrote) }
        its(:count) { should == 9 }
        it { subject.to_a.should == graph.v.out_e(:uses, :wrote).in_v.to_a }
      end
    end

    describe '#in' do
      subject { graph.v.in }
      it { should be_a Pacer::Core::Graph::VerticesRoute }
      its(:count) { should == 14 }
      its(:to_a) { should == graph.v.in_e.out_v.to_a }
      describe '(:uses, :wrote)' do
        subject { graph.v.in(:uses, :wrote) }
        its(:count) { should == 9 }
        it { subject.to_a.should == graph.v.in_e(:uses, :wrote).out_v.to_a }
      end
    end

    describe '#both' do
      subject { graph.v.both }
      it { should be_a Pacer::Core::Graph::VerticesRoute }
      its(:count) { should == 28 }
      describe '(:wrote)' do
        subject { graph.v.both(:wrote) }
        its(:count) { should == 8 }
        # These element ids only work under TinkerGraph:
        #it { subject.element_ids.to_a.should == %w[5 5 0 1 4 2 3 5] }
      end
    end
  end
end
