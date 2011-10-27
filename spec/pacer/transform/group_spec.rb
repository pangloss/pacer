require 'spec_helper'

Run.tg :read_only do
  use_pacer_graphml_data :read_only

  describe Pacer::Transform::Join do
    context 'with no key or value specified' do
      subject { graph.v.join }
      its(:count) { should == 7 }
      specify 'each element should be a node' do
        subject.each do |group|
          group[:key].should be_a graph.element_type(:vertex)
          group.property_keys.to_a.should == ['key']
        end
      end
    end

    context 'with key_route only' do
      subject { graph.v.join(:key) { |r| r[:type] } }

      its(:count) { should == 7 }
      its(:to_a) { should_not be_empty }
      specify 'each result should have one value' do
        subject.each do |group|
          group[:key].should be_a String
          group.property_keys.to_a.should == ['key']
        end
      end
    end

    context 'with key_route and value route' do
      let(:route) { graph.v.join(:key) { |r| r[:type] }.join }
      subject { route }

      specify 'each result should reflect an element' do
        subject.each.zip(graph.v.to_a) do |group, e|
          group[:key].should == e[:type]
          group.property_keys.to_set.should == Set['key', 'values']
          group[:values].last.element_id.should == e.element_id
        end
      end

      context '#multigraph' do
        subject { route.multigraph }
        it { should be_a Pacer::MultiGraph }

        its('v.count') { should == 3 }


        context 'person' do
          subject { route.multigraph.vertex 'person' }
          it 'should hove 2 values' do
            subject[:values].length.should == 2
          end
          it { subject[:values].should == graph.v(:type => 'person').to_a }
        end

        context 'project' do
          subject { route.multigraph.vertex 'project' }
          it 'should hove 2 values' do
            subject[:values].length.should == 4
          end
          it { subject[:values].should == graph.v(:type => 'project').to_a }
        end

        context 'reduced to a count' do
          subject do
            route.multigraph.v.reduce({}) do |h, v|
              h[v.element_id] = v[:values].count
              h
            end
          end
          specify 'it should have a count for values' do
            subject['project'].should == 4
            subject['person'].should == 2
            subject['group'].should == 1
          end
        end

        context 'reduced to a string' do
          subject do
            route.multigraph.v.reduce({}) do |h, v|
              h[v.element_id] = v[:values].map { |v| v[:name] }.join ', '
              h
            end
          end
          specify do
            subject['project'].should == 'blueprints, pipes, pacer, gremlin'
            subject['person'].should == 'pangloss, okram'
            subject['group'].should == 'tinkerpop'
          end
        end
      end
    end

    context 'with a key block that returns a literal value' do
      subject { graph.v.join { |r| r[:type] }.key { |r| r[:type].length } }
      its(:count) { should == 7 }
      specify 'each value should have a numeric key' do
        subject.each do |v|
          v[:key].should == v.element_id
          v[:key].should == v[:values].first.length
        end
      end
    end

    context 'with values_maps' do
      let(:counted_group) do
        graph.v.join(:count) { |r| r.out_e.counted.cap }.
          join(:out_e, &:out_e).
          key { |r| r[:type] }
      end
      subject do
        counted_group.multigraph
      end
      its('v.count') { should == 3 }
      specify { counted_group.count.should == 7 }
      specify 'combine(:count) should group the counts in a hash' do
        hash = Hash[subject.v[[:key, :count]].to_a]
        hash.should == {"project"=>[0, 1, 3, 2], "person"=>[1, 3], "group"=>[4]}
      end

      specify 'reduce summarizes edge labels for each type' do
        result = Hash[subject.v.map { |v| [v.element_id, v[:out_e].group_count { |e| e.label }] }.to_a]
        result.should == {"project" => {"uses"     => 5, "modelled_on" => 1},
                          "person"  => {"wrote"    => 4},
                          "group"   => {"projects" => 3, "member"      => 1}}
      end

      its(:inspect) { should == "#<MultiGraph>" }
      
      specify do
        counted_group.inspect.should == 
          "#<GraphV -> V-Join(#<V -> Obj(type)>: {:count=>#<V -> outE -> Obj-Cap(E-Counted)>, :out_e=>#<V -> outE>})>"
      end
    end
  end
end
