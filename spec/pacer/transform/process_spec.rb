require 'spec_helper'

shared_examples_for '#process' do
  describe 'simple element route' do
    subject do
      c = 0
      source.process { c += 1 }
    end
    its(:first) { should == source.first }
    its(:element_type) { should == :vertex }
  end

  describe 'with extensions' do
    let(:extended) { source.add_extensions([Tackle::SimpleMixin]) }
    let(:exts) { Set[] }

    subject { extended.process { |v| exts << v.extensions } }

    its('first.extensions') { should == [Tackle::SimpleMixin] }

    it 'should have the right extensions in the block' do
      subject.first
      exts.first.should == [Tackle::SimpleMixin, Pacer::Extensions::BlockFilterElement]
    end
  end
end

Run.tg :read_only do
  use_pacer_graphml_data :read_only

  context 'on route' do
    it_uses '#process' do
      let(:source) { graph.v }
    end
  end

  context 'on element' do
    it_uses '#process' do
      let(:source) { pangloss }
    end
  end
end
