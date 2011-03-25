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

      describe '#combine_all' do
        subject { route.combine_all }
        it { should be_a(Hash) }
        its(:length) { should == 3 }
        specify 'type = person should have 2 vertices' do
          subject['project'].values.count.should == 4
          subject['person'].values.count.should == 2
        end
      end

      describe '#combine' do
        subject { route.combine(:default) }
        it { should be_a(Hash) }
        it { should == {
          'project' => graph.v(:type => 'project').to_a,
          'person'  => graph.v(:type => 'person').to_a,
          'group'   => graph.v(:type => 'group').to_a
        } }
      end

      describe '#reduce_all' do
        context 'to count elements' do
          subject { route.reduce_all(0) { |t, name, value| t + 1 } }
          specify 'it should have a count for values' do
            subject['project'].values.should == 4
            subject['person'].values.should == 2
            subject['group'].values.should == 1
          end
        end

        context 'to join names' do
          subject { route.reduce_all(nil) { |t, name, value| [t, value[:name]].compact.join ', ' } }
          specify 'it should have a count for values' do
            subject['project'].values.should == 'blueprints, pipes, pacer, gremlin'
            subject['person'].values.should == 'pangloss, okram'
            subject['group'].values.should == 'tinkerpop'
          end
        end
      end

      describe '#reduce' do
        context 'to count properties' do
          subject { route.reduce(proc { |h, k| h[k] = 0 }, :default) { |t, value| t + value.properties.count } }
          specify 'it should have a count for values' do
            subject['project'].should == 8
            subject['person'].should == 4
            subject['group'].should == 2
          end
        end
      end
    end

    context 'with key_map' do
      subject { graph.v.group.key_map { |r| r[:type] } }
      its(:count) { should == 7 }
      its(:to_a) { should_not be_empty }
    end

    context 'with values_maps' do
      subject do
        graph.v.group.
          values_map(:count) { |r| r.out_e.count }.
          values_route(:out_e) { |r| r.out_e }.
          key_route { |r| r[:type] }
      end
      its(:count) { should == 7 }
      its(:to_a) { should_not be_empty }
      specify 'combine(:count) should group the counts in a hash' do
        hash = subject.combine(:count)
        hash.should == {"project"=>[0, 1, 3, 2], "person"=>[1, 3], "group"=>[4]}
      end

      specify 'reduce summarizes edge labels for each type' do
        result = subject.reduce(proc { |h, k| h[k] = Hash.new(0) }, :out_e) do |h, e|
          h[e.label] += 1
          h
        end
        result.should == {"project" => {"uses"     => 5, "modelled_on" => 1},
                          "person"  => {"wrote"    => 4},
                          "group"   => {"projects" => 3, "member"      => 1}}
      end

      its(:inspect) { should == "#<GraphV -> V-Group(#<V -> Obj(type)>: {:count=>#<V -> Obj-Map>, :out_e=>#<V -> outE>})>" }
    end
  end
end
