require 'spec_helper'

Run.all :read_only do
  use_pacer_graphml_data :read_only

  describe Pacer::Wrappers::EdgeWrapper do

    let(:e_exts) { [Tackle::SimpleMixin, TP::Wrote] }
    let(:e_wrapper_class) { Pacer::Wrappers::EdgeWrapper.wrapper_for e_exts }

    subject { e_wrapper_class }

    it { should_not be_nil }
    its(:route_conditions) { should == { label: 'wrote' } }
    its(:extensions) { should == e_exts }

    describe 'instance' do
      subject do
        e = e_wrapper_class.new pangloss_wrote_pacer
        e.graph = graph
        e
      end
      it               { should_not be_nil }
      its(:element)    { should_not be_nil }
      it               { should == pangloss_wrote_pacer }
      it               { should_not equal pangloss_wrote_pacer }
      its(:element_id) { should == pangloss_wrote_pacer.element_id }
      its(:extensions) { should == e_exts }

      describe 'with more extensions added' do
        subject { e_wrapper_class.new(pacer).add_extensions([Pacer::Utils::TSort]) }
        its(:class) { should_not == e_wrapper_class }
        its(:extensions) { should == e_exts + [Pacer::Utils::TSort] }
      end
    end
  end
end
