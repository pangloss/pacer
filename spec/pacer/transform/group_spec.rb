require 'spec_helper'

for_tg :read_only do
  use_pacer_graphml_data :read_only

  describe Pacer::Transform::Group do
    context 'with no key or value specified' do
      subject { graph.v.group }
      its(:count) { should == 7 }
      specify 'each element should be a node' do
        subject.each do |group|
          group.key.should be_a graph.element_type(:vertex)
          group.values.length.should == 1
          group.values.first.should be_a graph.element_type(:vertex)
        end
      end
    end

    context 'with key_route' do
      let(:route) { graph.v.group.key_route { |r| r[:type] } }
      subject { route }

      its(:count) { should == 7 }
      its(:to_a) { should_not be_empty }
      specify 'each result should have one value' do
        subject.each do |group|
          group.key.should be_a String
          group.values.length.should == 1
          group.values.first.should be_a graph.element_type(:vertex)
        end
      end

      specify 'each result should reflect an element' do
        subject.each.zip(graph.v.to_a) do |group, e|
          group.key.should == e[:type]
          group.values.first.element_id.should == e.element_id
        end
      end

      describe '#combine' do
        subject { route.combine }
        it { should be_a(Hash) }
        its(:length) { should == 3 }
        specify 'type = person should have 2 vertices' do
          subject['project'].values.count.should == 4
          subject['person'].values.count.should == 2
        end
      end
    end

    context 'with key_map' do
      subject { graph.v.group.key_map { |r| r[:type] } }
      its(:count) { should == 7 }
      its(:to_a) { should_not be_empty }
    end
  end
end
