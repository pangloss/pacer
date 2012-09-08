require 'spec_helper'

shared_examples_for '#map' do
  describe 'simple element route' do
    subject do
      c = 0
      source.map { c += 1 }
    end
    its(:first) { should == 1 }
    its(:element_type) { should == :object }
  end

  describe 'with extensions' do
    let(:extended) { source.add_extensions([Tackle::SimpleMixin]) }

    subject { extended.map { |v| v.extensions } }

    its(:first) { should == [Tackle::SimpleMixin] }
    its(:element_type) { should == :object }

    context 'with vertex result type' do
      subject { extended.map(element_type: :vertex) { |v| v } }
      its(:element_type) { should == :vertex }
      its(:extensions) { should == [] }
    end

    context 'with extended vertex result type' do
      let(:exts) { [] }
      subject { extended.map(element_type: :vertex, extensions: TP::Person) { |v| exts << v.extensions; v } }
      its(:element_type) { should == :vertex }
      its(:extensions) { should == [TP::Person] }
      it 'should use the source - not the result - extension in the block' do
        v = subject.first
        v.extensions.should == [TP::Person]
        exts.first.should == [Tackle::SimpleMixin]
      end
    end
  end
end

Run.tg :read_only do
  use_pacer_graphml_data :read_only

  context 'on route' do
    it_uses '#map' do
      let(:source) { graph.v }
    end
  end

  context 'on element' do
    it_uses '#map' do
      let(:source) { pangloss }
    end
  end
end
