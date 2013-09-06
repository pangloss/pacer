require 'spec_helper'

Run.all(:read_write) do
  use_pacer_graphml_data(:read_write)

  describe '#property?' do
    before do
      setup_data
      graph.create_vertex other: 'hi'
      graph.create_vertex falsy: false
      graph.create_vertex zero: 0
    end

    it 'should filter vertices that do not have the given property' do
      graph.v.count.should == 10
      graph.v.property?(:name).count.should == 7
      graph.v.property?(:other).count.should == 1
    end

    it 'should work even if the value is falsy' do
      graph.v.count.should == 10
      graph.v.property?(:name).count.should == 7
      graph.v.property?(:zero).count.should == 1

      unless graph_name == 'mcfly'
        graph.v.property?(:falsy).count.should == 1
      end
    end
  end
end

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
      its(:to_set) { should == graph.v.out_e.in_v.to_set }

      describe '(:uses, :wrote)' do
        subject { graph.v.out(:uses, :wrote) }
        its(:count) { should == 9 }
        it { subject.to_set.should == graph.v.out_e(:uses, :wrote).in_v.to_set }
      end

      it 'should not apply extensions to new route' do
        graph.v(Tackle::SimpleMixin).out.extensions.should == []
      end
    end

    describe '#in' do
      subject { graph.v.in }
      it { should be_a Pacer::Core::Graph::VerticesRoute }
      its(:count) { should == 14 }
      its(:to_set) { should == graph.v.in_e.out_v.to_set }
      describe '(:uses, :wrote)' do
        subject { graph.v.in(:uses, :wrote) }
        its(:count) { should == 9 }
        it { subject.to_set.should == graph.v.in_e(:uses, :wrote).out_v.to_set }
      end

      it 'should not apply extensions to new route' do
        graph.v(Tackle::SimpleMixin).in.extensions.should == []
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

      it 'should not apply extensions to new route' do
        graph.v(Tackle::SimpleMixin).both.extensions.should == []
      end
    end
  end
end

Run.tg(:read_only) do
  context Pacer::Core::Graph::VerticesRoute do
    use_pacer_graphml_data(:read_only)

    describe '#out_e' do
      it { graph.v.out_e.should be_an_edges_route }
      it { graph.v.out_e(:label).should be_a(Pacer::Route) }
      it { graph.v.out_e(:label) { |x| true }.should be_a(Pacer::Route) }
      it { graph.v.out_e { |x| true }.should be_a(Pacer::Route) }

      it('should have all edges') do
        Set[*graph.v.out_e].should == Set[*graph.e]
      end

      it { graph.v.out_e.count.should >= 1 }

      specify 'with label filter should work with path generation' do
        r = graph.v.out_e.in_v.in_e { |e| e.label == 'wrote' }.out_v
        paths = r.paths
        paths.first.should_not be_nil
        graph.v.out_e.in_v.in_e(:wrote).out_v.paths.to_a.should == paths.to_a
      end
    end
  end
end

Run.tg do
  use_pacer_graphml_data

  context Pacer::Core::Graph::VerticesRoute do
    describe :add_edges_to do
      before do
        setup_data
      end

      let(:pangloss) { graph.v(:name => 'pangloss') }
      let(:pacer) { graph.v(:name => 'pacer') }

      context '1 to 1' do
        before do
          @result = pangloss.add_edges_to(:likes, pacer, :pros => "it's fast", :cons => nil)
        end

        subject { @result.first }

        it { should_not be_nil }
        its(:out_vertex) { should == pangloss.first }
        its(:in_vertex) { should == pacer.first }
        its(:label) { should == 'likes' }

        it 'should store properties' do
          subject[:pros].should == "it's fast"
        end

        it 'should not add properties with null values' do
          subject.getPropertyKeys.should_not include('cons')
        end
      end

      context 'many to many' do
        let(:people) { graph.v(:type => 'person') }
        let(:projects) { graph.v :type => 'project' }

        subject { people.add_edges_to(:uses, projects) }

        it { should be_a(Pacer::Core::Route) }
        its(:element_type) { should == :edge }
        its(:count) { should == 8 }
        its('back.back.element_type') { should == :object }
        its('back.count') { should == 8 }

        specify 'all edges in rasge should exist' do
          subject.each do |edge|
            edge.should_not be_nil
            edge.label.should == 'uses'
          end
        end
      end

      context 'edge cases' do
        it 'should do nothing if there are no source vertices' do
          result = graph.v(:name => 'no match').add_edges_to(:likes, pacer, :pros => "it's fast", :cons => nil)
          result.should be_nil
        end

        it 'should do nothing if there are no target vertices' do
          result = pangloss.add_edges_to(:likes, graph.v(:name => 'I hate everytihng'))
          result.should be_nil
        end

        it 'should associate to a single element' do
          result = pangloss.add_edges_to(:likes, pacer.first)
          edge = result.first
          edge.should_not be_nil
        end

        it 'should do nothing if target is nil' do
          result = pangloss.add_edges_to(:likes, nil)
          result.should be_nil
        end

        it 'should work if the source is a simple vertex' do
          result = pangloss.first.add_edges_to(:likes, pacer)
          result.should_not be_empty
        end
      end
    end
  end
end
