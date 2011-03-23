require 'spec_helper'

for_tg :read_only do
  use_pacer_graphml_data :read_only

  describe Pacer::Transform::Group do
    context 'with no key or value specified' do
      subject { graph.v.group }
      its(:count) { should == 7 }
      specify 'each element should be a node' do
        subject.each do |key, values|
          key.should be_a graph.element_type(:vertex)
          values.length.should == 1
          values.first.length.should == 1
          values.first.first.should be_a graph.element_type(:vertex)
        end
      end
    end
    context 'with key_route' do
      subject { graph.v.group.key_route { |r| r[:type] }.values_route { |r| r[:type]}  }
      its(:count) { should == 7 }
      its(:to_a) { should_not be_empty }
      specify 'each result should have one value' do
        subject.each do |key, values|
          key.should be_a String
          values.length.should == 1
          values.first.length.should == 1
          values.first.first.should be_a String
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
